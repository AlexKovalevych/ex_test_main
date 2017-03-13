defmodule Gt.DataSource.Pomadorro do
  alias Gt.{
    Repo,
    ProjectUser,
    Payment,
    XeProvider,
    ProjectUserGame,
    ProjectGame,
    PokerGame,
    ProjectUserBonus,
    PokerBonus,
    DataSourceRegistry,
  }
  import Ecto.Query
  require Logger
  use Timex

  # Poker games take a lot of time
  @request_timeout 1200_000

  @payment_state_map %{
    "-4" => Payment.state(:cancelled),
    "-3" => Payment.state(:cancelled),
    "-2" => Payment.state(:cancelled),
    "-1" => Payment.state(:failure),
    "0" => Payment.state(:new),
    "1" => Payment.state(:approved),
  }

  @payment_type_map %{
    "payin" => Payment.type(:deposit),
    "payout" => Payment.type(:withdrawal),
  }

  def process_file(data_source, {filename, index}, total_files) do
    Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    |> File.read!()
    |> process_data(data_source, data_source.subtype, index, total_files)
  end

  defp process_data(data, data_source, subtype, index, total_files) do
    data = data |> Poison.decode!()
    count = Enum.count(data)
    Logger.info("Parsing #{count} items")
    DataSourceRegistry.delete(data_source.id, :new_user_stats)
    DataSourceRegistry.save(data_source.id, :total, total_files * count * 2)
    DataSourceRegistry.save(data_source.id, :processed, index * count * 2)

    data
    |> ParallelStream.each(fn data ->
      case subtype do
        "casino_users" -> parse_users(data_source, data)
        "casino_invoices" -> parse_payments(data_source, data)
        "casino_bonuses" -> parse_casino_bonuses(data_source, data)
        "casino_games" -> parse_games(data_source, data)
        "poker_bonuses" -> parse_poker_bonuses(data_source, data)
        "poker_games_raw" -> parse_poker_games(data_source, data)
      end
    end)
    |> Enum.reduce(0, fn _, acc -> acc + 1 end)
    user_ids = DataSourceRegistry.find(data_source.id, :new_user_stats) || []
    Logger.info("Processing new user stats for #{Enum.count(user_ids)} users")
    user_ids
    |> Enum.each(fn {_, {user, from, to, count}} ->
      ProjectUser.calculate_stats(user, from, to)
      ProjectUser.deps_wdrs_cache(user)
      ProjectUser.calculate_vip_levels(user)
      DataSourceRegistry.increment(data_source.id, :processed, count)
    end)
  end

  def process_api(data_source) do
    diff = Timex.diff(data_source.start_at, data_source.end_at, :days) |> abs
    interval = Interval.new(from: data_source.start_at, until: [days: diff], step: [days: 1], right_open: false)
    total_files = Enum.count(interval) * Enum.count(data_source.subtypes)

    interval
    |> Enum.with_index
    |> Enum.each(fn {date, i} ->
      data_source.subtypes
      |> Enum.with_index
      |> Enum.each(fn {subtype, j} ->
        query = %{
          cm: subtype,
          from: Timex.format!(date, "{ISOdate}"),
          to: Timex.shift(date, days: 1) |> Timex.format!("{ISOdate}")
        }
        Logger.metadata(subtype: subtype)
        Logger.info("Load data from url #{data_source.host} with params #{inspect(query)}")
        response = HTTPotion.get(data_source.host, query: query, timeout: @request_timeout)
        if HTTPotion.Response.success?(response) do
          process_data(response.body, data_source, subtype, Enum.count(data_source.subtypes) * i + j, total_files)
        else
          Logger.error("Can't load pomadorro #{subtype} for date: #{Timex.format!(date, "{ISOdate}")}")
          exit(inspect(response))
        end
      end)
    end)

    DataSourceRegistry.delete(data_source.id, :new_user_stats)
  end

  defp parse_users(data_source, data) do
    %{"currency" => currency,
      "ip" => ip,
      "partner" => query1,
      "reg_date" => reg_date,
      "user_id" => item_id,
    } = data
    lang = Map.get(data, "reg_lang", nil)
    reg_date = parse_date(reg_date)
    project_user = ProjectUser
    |> ProjectUser.by_project_item_id(data_source.project.id, item_id)
    |> Repo.one
    if project_user do
      project_user
      |> ProjectUser.changeset(%{
        lang: lang,
        currency: currency,
        reg_ip: ip,
        query1: query1,
        reg_d: reg_date
      })
      |> Repo.update!
    else
      %ProjectUser{}
      |> ProjectUser.changeset(%{
        item_id: item_id,
        project_id: data_source.project.id,
        lang: lang,
        currency: currency,
        reg_ip: ip,
        query1: query1,
        reg_d: reg_date
      })
      |> Repo.insert!
      |> Repo.preload(:project)
      |> Gt.Amqp.Messages.Dmp.create_by_user()
    end
    DataSourceRegistry.increment(data_source.id, :processed, 2)
  end

  defp parse_payments(data_source, data) do
    %{"status" => state,
      "user_id" => user_item_id,
      "payment_group_id" => group_id,
      "finish_date" => commit_date,
      "ip" => ip,
      "currency" => currency,
      "date" => date,
      "amount" => user_sum,
      "tid" => item_id,
      "type" => type
    } = data
    state = @payment_state_map[to_string(state)]
    type = @payment_type_map[to_string(type)]
    commit_date = parse_date(commit_date)
    date = parse_date(date)
    sum = XeProvider.convert(currency, "USD", date, user_sum) |> round
    user_sum = round(user_sum)

    project_user = ProjectUser.get_or_create(data_source.project.id, user_item_id, date)

    case Payment.by_project_item_id(Payment, data_source.project.id, item_id) |> Repo.one do
      nil ->
        Payment.changeset(%Payment{}, %{
          state: state,
          group_id: group_id,
          commit_date: commit_date,
          ip: ip,
          currency: currency,
          date: date,
          user_sum: user_sum,
          sum: sum,
          type: type,
          project_id: project_user.project.id,
          project_user_id: project_user.id,
          item_id: item_id,
        })
        |> Repo.insert!
        |> Repo.preload(:project)
        |> Gt.Amqp.Messages.Dmp.create_by_payment(user_item_id)
      payment ->
        Payment.changeset(payment, %{
          state: state,
          group_id: group_id,
          commit_date: commit_date,
          ip: ip,
          currency: currency,
          date: date,
          user_sum: user_sum,
          sum: sum,
          type: type,
          project_id: project_user.project.id,
          project_user_id: project_user.id,
        })
        |> Repo.update!
    end
    GenServer.call(DataSourceRegistry, {:new_user_stats, {project_user, Timex.to_date(date)}, data_source.id})
    DataSourceRegistry.increment(data_source.id, :processed)
  end

  defp parse_casino_bonuses(data_source, data) do
    %{"currency" => currency,
      "amount" => amount,
      "type" => type,
      "user_id" => user_item_id,
      "date" => date
    } = data
    date = parse_date(date)
    project_user = ProjectUser.get_or_create(data_source.project.id, user_item_id, date, currency)

    changeset = %ProjectUserBonus{}
    |> ProjectUserBonus.changeset(%{
      date: date,
      currency: currency,
      amount: amount,
      type: type,
      project_user_id: project_user.id,
      project_id: data_source.project.id,
    })
    id = ProjectUserBonus.generate_id(Ecto.Changeset.apply_changes(changeset))
    if !Repo.get(ProjectUserBonus, id) do
      changeset
      |> Ecto.Changeset.put_change(:id, id)
      |> Repo.insert!
    end
    DataSourceRegistry.increment(data_source.id, :processed, 2)
  end

  defp parse_games(data_source, data) do
    %{
      "bets" => user_bets,
      "wins" => user_wins,
      "user_id" => user_item_id,
      "wins_cnt" => wins_num,
      "bets_cnt" => bets_num,
      "gameref" => game_ref,
      "date" => date,
      "currency" => currency
    } = data
    date = parse_date(date)
    project_user = ProjectUser.get_or_create(data_source.project.id, user_item_id, date, currency)
    project_game = ProjectGame
                   |> ProjectGame.by_project(data_source.project.id)
                   |> ProjectGame.by_name(game_ref)
                   |> limit(1)
                   |> Repo.one

    project_game = cond do
      is_nil(project_game) && game_ref != "" ->
        %ProjectGame{}
        |> ProjectGame.changeset(%{
          project_id: data_source.project.id,
          name: game_ref,
          is_risk: ProjectGame.is_risk(game_ref),
          is_mobile: ProjectGame.is_mobile(game_ref),
        })
        |> Repo.insert!
      true -> project_game
    end

    if project_game do
      changeset = %ProjectUserGame{}
      |> ProjectUserGame.changeset(%{
        user_bets: round(user_bets),
        user_wins: round(user_wins),
        bets_num: bets_num,
        bets_sum: XeProvider.convert(currency, "USD", date, user_bets) |> round,
        wins_num: wins_num,
        wins_sum: XeProvider.convert(currency, "USD", date, user_wins) |> round,
        game_ref: game_ref,
        date: date,
        currency: currency,
        project_user_id: project_user.id,
        project_game_id: project_game.id,
        project_id: data_source.project.id,
      })
      id = ProjectUserGame.generate_id(Ecto.Changeset.apply_changes(changeset))

      if !Repo.get(ProjectUserGame, id) do
        changeset
        |> Ecto.Changeset.put_change(:id, id)
        |> Repo.insert!
      end
    end
    DataSourceRegistry.increment(data_source.id, :processed, 2)
  end

  defp parse_poker_bonuses(data_source, data) do
    %{"currency" => currency,
      "amount" => amount,
      "type" => type,
      "user_id" => user_item_id,
      "date" => date
    } = data
    date = parse_date(date)
    project_user = ProjectUser.get_or_create(data_source.project.id, user_item_id, date, currency)
    changeset = %PokerBonus{}
    |> PokerBonus.changeset(%{
      date: date,
      currency: currency,
      amount: amount,
      type: type,
      project_user_id: project_user.id,
      project_id: data_source.project.id,
    })
    id = PokerBonus.generate_id(Ecto.Changeset.apply_changes(changeset))
    if !Repo.get(PokerBonus, id) do
      changeset
      |> Ecto.Changeset.put_change(:id, id)
      |> Repo.insert!
    end
    DataSourceRegistry.increment(data_source.id, :processed, 2)
  end

  def parse_poker_games(data_source ,data) do
    %{
      "buyin" => user_buy_in,
      "pk_currency" => currency,
      "cashout" => wdr,
      "rake" => user_rake,
      "rebuyin" => rebuy_in,
      "session_id" => session_id,
      "session_type" => session_type,
      "date" => date,
      "bet" => total_bet,
      "payout" => total_payment,
      "user_id" => user_item_id,
    } = data
    date = parse_date(date)
    project_user = ProjectUser.get_or_create(data_source.project.id, user_item_id, date, currency)
    changeset = %PokerGame{}
    |> PokerGame.changeset(%{
      date: date,
      user_buy_in: user_buy_in,
      buy_in: XeProvider.convert(currency, "USD", date, user_buy_in),
      wdr: wdr,
      rake_sum: XeProvider.convert(currency, "USD", date, user_rake),
      user_rake: user_rake,
      rebuy_in: rebuy_in,
      currency: currency,
      session_id: session_id,
      session_type: session_type,
      total_bet: total_bet,
      total_payment: total_payment,
      project_user_id: project_user.id,
      project_id: data_source.project.id,
    })
    id = PokerGame.generate_id(Ecto.Changeset.apply_changes(changeset))
    if !Repo.get(PokerGame, id) do
      changeset
      |> Ecto.Changeset.put_change(:id, id)
      |> Repo.insert!
    end
    DataSourceRegistry.increment(data_source.id, :processed, 2)
  end

  defp parse_date(nil), do: nil

  defp parse_date(date) do
    case String.length(date) do
      19 -> Timex.parse!(date, "{ISOdate} {ISOtime}")
      25 -> Timex.parse!(date, "{ISOdate} {ISOtime}{Z:}")
    end
  end
end
