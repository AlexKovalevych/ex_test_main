defmodule Gt.DataSource.EventLog do
  alias Gt.Api.EventLogResponse
  alias Gt.Api.EventLogEvent
  alias Gt.DataSourceRegistry
  alias Gt.ProjectUser
  alias Gt.Payment
  alias Gt.Repo
  alias Gt.Api.EventLog, as: Api
  alias Gt.Api.WlRest, as: WlApi
  require Logger

  def process_file(data_source, {filename, index}, total_files) do
    Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    |> File.read!()
    |> Poison.decode!(as: %EventLogResponse{events: [%EventLogEvent{}]})
    |> process_data(data_source, index, total_files)
  end

  defp process_data(%EventLogResponse{events: events}, data_source, index, total_files) do
    count = Enum.count(events)
    Logger.info("Parsing #{count} items")
    DataSourceRegistry.delete(data_source.id, :new_user_stats)
    DataSourceRegistry.save(data_source.id, :total, total_files * count)
    DataSourceRegistry.save(data_source.id, :processed, index * count)

    events
    |> ParallelStream.each(fn event ->
      case event.name do
        "user_register" -> new_user_event(data_source, event)
        "user_changed" -> change_event(data_source, event)
        "user_emailconfirm" -> email_confirm(data_source, event)
        "user_depositcomplete" -> payment_event(data_source, event)
        "user_cashoutcomplete" -> payment_event(data_source, event)
        "user_depositerror" -> payment_event(data_source, event)
        "user_cashoutcancel" -> payment_event(data_source, event)
        _ -> nil
      end
      DataSourceRegistry.increment(data_source.id, :processed)
    end)
    |> Enum.reduce(0, fn _, acc -> acc + 1 end)
    user_ids = DataSourceRegistry.find(data_source.id, :new_user_stats) || []
    Logger.info("Processing new user stats for #{Enum.count(user_ids)} users")
    user_ids
    |> Enum.each(fn {_, {user, from, to, count}} ->
      ProjectUser.calculate_stats(user, from, to)
      ProjectUser.deps_wdrs_cache(user)
      ProjectUser.calculate_vip_levels(user)
    end)
  end

  defp change_event(data_source, event) do
    data = event.data
    item_id = Map.get(data, "user_id")
    Logger.info("User changed event - #{item_id}")
    # only currency implemented now
    currency = Map.get(data, "currency")
    if currency do
      ProjectUser
      |> ProjectUser.by_project_item_id(data_source.project.id, item_id)
      |> Repo.update_all(set: [currency: currency])
    end
  end

  defp new_user_event(data_source, event) do
    data = event.data
    item_id = data |> Map.get("user_id")
    user = ProjectUser
    |> ProjectUser.by_project_item_id(data_source.project.id, item_id)
    |> Repo.one

    if user do
      Logger.info("User #{item_id} already in db - #{user.id}")
      user
    else
      date = Timex.from_unix(event.time)
      user = %ProjectUser{}
      |> ProjectUser.changeset(%{
        project_id: data_source.project.id,
        item_id: item_id,
        red_d: date,
        query1: Map.get(data, "query1"),
        reg_ref1: Map.get(data, "referrer1"),
        is_active: true,
        is_test: false,
        lang: Map.get(data, "lang"),
        email: Map.get(data, "email"),
        login: Map.get(data, "login"),
        nick: Map.get(data, "nick"),
        reg_ip: Map.get(data, "ip"),
        last_d: date,
        currency: Map.get(data, "currency"),
        email_hash: Map.get(data, "email_hash"),
        email_encrypted: Map.get(data, "email_encrypted")
      })
      |> Repo.insert!
      |> Repo.preload(:project)
      Gt.Amqp.Messages.Dmp.create_by_user(user)
      Logger.info("New user from event, id = #{user.id}")
      user
    end
  end

  defp email_confirm(data_source, event) do
    item_id = Map.get(event.data, "user_id")
    Logger.info("Email confirmed for user #{item_id}")
    ProjectUser
    |> ProjectUser.by_project_item_id(data_source.project.id, item_id)
    |> Repo.update_all(set: [email_confirmed: true])
  end

  defp payment_event(data_source, event) do
    data = event.data
    item_id = "#{Map.get(data, "trid")}_wl"
    project_id = data_source.project.id
    user_item_id = Map.get(data, "user_id")

    user = ProjectUser
    |> ProjectUser.by_project_item_id(project_id, user_item_id)
    |> Repo.one

    # can't find user by glow_id, load item_id from proxy
    user = case Enum.empty?(data_source.files) do
      true ->
        case user do
          nil ->
            case data_source.wl_client do
              nil -> get_user_register_event(data_source, user_item_id)
              _ -> get_user_from_wl_rest_api(data_source, user_item_id)
            end
          _ -> user
        end
      _ ->
        # Its a local source, we can't get user from external source
        user
    end

    if !user do
      message = "Invalid user #{user_item_id} for payment #{item_id}"
      Logger.error(message)
      raise message
    end

    payment = Payment
              |> Payment.by_project_item_id(project_id, item_id)
              |> Repo.one
    if !payment do
      {state, type} = case Map.get(event, "name") do
        "user_depositcomplete" -> {Payment.state(:approved), Payment.type(:deposit)}
        "user_depositerror" -> {Payment.state(:failure), Payment.type(:deposit)}
        "user_cashoutcomplete" -> {Payment.state(:approved), Payment.type(:withdrawal)}
        "user_cashoutcancel" -> {Payment.state(:cancelled), Payment.type(:withdrawal)}
      end

      multiply = case data_source.divide_by_100 do
        true -> 1
        _ -> 100
      end

      user_sum = Map.get(data, "amount_uCur") * multiply |> abs |> round
      sum = Map.get(data, "amount") * multiply |> abs |> round
      info = Map.get(data, "info")
      currency = Map.get(info, "currency", Map.get(info, "result_data") |> Map.get("currency"))
      date = Timex.from_unix(event.time)
      Payment
      |> Payment.changeset(%{
        item_id: item_id,
        project_id: project_id,
        project_user_id: user.id,
        date: date,
        type: type,
        state: state,
        user_sum: user_sum,
        currency: currency,
        sum: sum,
        info: %{additional_data: Poison.encode!(info)},
        system: Map.get(data, "system")
      })
      |> Repo.insert!
      |> Repo.preload(:project)
      |> Gt.Amqp.Messages.Dmp.create_by_payment(user_item_id)
      Logger.info("Insert payment #{item_id}")
      GenServer.call(DataSourceRegistry, {:new_user_stats, {user, Timex.to_date(date)}, data_source.id})
    end

  end

  defp get_user_register_event(data_source, user_item_id) do
    Logger.info("Load user #{user_item_id} from event_log")
    api = %Api{url: data_source.host, app_key: data_source.client, private_key: data_source.private_key}
    case Api.get_register_event(api, data_source.uri, user_item_id) do
      {:ok, event} ->
        new_user_event(data_source, event)
      {:error, reason} ->
        Logger.warn("Can't load user from event_log. Project: #{data_source.client}, id: #{user_item_id}. #{reason}")
        nil
    end
  end

  defp get_user_from_wl_rest_api(data_source, user_item_id) do
    wl_api = %WlApi{url: data_source.wl_host, client: data_source.client, key: data_source.private_key}
    case WlApi.get_player(wl_api, user_item_id) do
      {:error, reason} ->
        Logger.warn("Can't load player from wl_rest. Project: #{data_source.client}, id: #{user_item_id}. #{reason}")
        nil
      {:ok, player} ->
        case ProjectUser.by_project_item_id(ProjectUser, data_source.project.id, player.id) |> Repo.one do
          nil ->
            date = Timex.from_unix(player.registered_at)
            last_date = Timex.from_unix(player.last_visit_at)
            user = ProjectUser
            |> ProjectUser.changeset(%{
              project_id: data_source.project.id,
              item_id: player.id,
              reg_d: date,
              is_active: player.is_active,
              is_test: player.is_test,
              email: player.email,
              login: player.login,
              nick: player.nickname,
              reg_ip: player.ip,
              last_d: last_date,
              currency: player.currency,
              last_name: player.lastname,
              first_name: player.firstname
            })
            |> Repo.insert!
            Gt.Amqp.Messages.Dmp.create_by_user(user)
            Logger.info("New user from wl_rest, id: #{user.id}")
            user
          user ->
            Logger.info("User #{player.id} already in db, id - #{user.id}")
            user
        end
    end
  end
end
