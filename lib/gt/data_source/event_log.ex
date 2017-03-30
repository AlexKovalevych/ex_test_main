defmodule Gt.DataSource.EventLog do
  alias Gt.Api.EventLogResponse
  alias Gt.Api.EventLogEvent
  alias Gt.DataSourceRegistry
  alias Gt.ProjectUser
  alias Gt.Payment
  alias Gt.Repo
  require Logger

  def process_file(data_source, {filename, index}, total_files) do
    Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    |> File.read!()
    |> Poison.decode!(as: %EventLogResponse{events: [%EventLogEvent{}]})
    |> process_data(data_source, index, total_files)
  end

  defp process_data(%EventLogResponse{events: events} = data, data_source, index, total_files) do
    count = Enum.count(events)
    Logger.info("Parsing #{count} items")
    DataSourceRegistry.delete(data_source.id, :new_user_stats)
    DataSourceRegistry.save(data_source.id, :total, total_files * count * 2)
    DataSourceRegistry.save(data_source.id, :processed, index * count * 2)

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

  defp change_event(data_source, event) do
    data = Map.get(event, "data")
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
    item_id = Map.get(event, "data") |> Map.get("user_id")
    user = ProjectUser
    |> ProjectUser.by_project_item_id(data_source.project.id, item_id)
    |> Repo.one

    if user do
      Logger.info("User #{item_id} already in db - #{user.id}")
    else
      date = Timex.from_unix(Map.get(event, "time"))
      data = Map.get(event, "data")
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
      |> Gt.Amqp.Messages.Dmp.create_by_user()
      Logger.info("New user from event, id = #{user.id}")
    end
  end

  defp email_confirm(data_source, event) do
    item_id = Map.get(event, "user_id")
    Logger.info("Email confirmed for user #{item_id}")
    ProjectUser
    |> ProjectUser.by_project_item_id(data_source.project.id, item_id)
    |> Repo.update_all(set: [email_confirmed: true])
  end

  defp payment_event(data_source, event) do
    data = Map.get(event, "data")
    item_id = "#{Map.get(data, "trid")}_wl"
    project_id = data_source.project.id
    user_item_id = Map.get(data, "user_id")

    user = ProjectUser
    |> ProjectUser.by_project_item_id(project_id, user_item_id)
    |> Repo.one

    # can't find user by glow_id, load item_id from proxy
    user = if !user do
        #if ($this->wlClient) {
            #$user = $this->fetchUserFromWlRestApi($projectUserItemId);
        #} else {
            #$user = $this->fetchUserRegisterEvent($projectUserItemId);
        #}
    else
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

      user_sum = Map.get(data, "amount_uCur") * 100 |> abs |> round
      sum = Map.get(data, "amount") * 100 |> abs |> round
      info = Map.get(data, "info")
      currency = Map.get(info, "currency", Map.get(info, "result_data") |> Map.get("currency"))
      date = Timex.from_unix(Map.get(event, "time"))
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
end
