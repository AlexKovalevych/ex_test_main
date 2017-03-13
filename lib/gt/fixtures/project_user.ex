defmodule Gt.Fixtures.ProjectUser do
  use Timex
  alias Gt.ProjectUser
  alias Gt.Phone
  alias Gt.Project
  alias Gt.Repo
  require Logger
  import Ecto.Query

  @now Timex.now

  def run do
    data = File.read! Path.join(__DIR__, "project_users.json")
    project_users = Poison.decode!(data)
    projects = Project
               |> where([p], p.title in ["Loto 1", "Loto 2", "Loto 3", "Loto 4", "Loto 5", "Loto 6", "Loto 7", "Loto 8", "Loto 9"])
               |> Gt.Repo.all

    Enum.each(projects, fn project ->
      project_users
      |> ParallelStream.each(&get_project_user(project, &1))
      #|> ParallelStream.each(&Repo.insert!/1)
      |> Enum.into([])
    end)
  end

  def get_project_user(project, data) do
    [
      reg_past_days,
      last_past_days,
      first_dep_past_days,
      currency,
      email_unsub_types,
      email_valid,
      first_dep_sum,
      has_bonus,
      is_active,
      _is_test,
      item_id,
      lang,
      phones,
      _,
      reg_ref1,
      segment,
      segment_upd_t,
      sms_unsub_types,
      _,
      query1,
      status,
      cash_real,
      cash_user_real
    ] = data

    reg_date = @now |> Timex.shift(days: -reg_past_days) |> Timex.to_naive_datetime
    last_date = @now |> Timex.shift(days: -last_past_days) |> Timex.to_naive_datetime
    first_dep_date = @now |> Timex.shift(days: -first_dep_past_days) |> Timex.to_naive_datetime
    item_id = case project.title do
      "Loto 1" -> item_id
      "Loto 2" -> item_id <> "2"
      "Loto 3" -> item_id <> "3"
      "Loto 4" -> item_id <> "4"
      "Loto 5" -> item_id <> "5"
      "Loto 6" -> item_id <> "32"
      "Loto 7" -> item_id <> "7"
      "Loto 8" -> item_id <> "8"
      "Loto 9" -> item_id <> "9"
    end

    phones = case Enum.empty?(phones) do
      true -> []
      _ -> [Phone.changeset(%Phone{}, phones) |> Ecto.Changeset.apply_changes]
    end

    ProjectUser.changeset(%ProjectUser{}, %{
      item_id: item_id,
      email_valid: email_valid,
      lang: lang,
      currency: currency,
      is_active: is_active,
      is_test: false,
      has_bonus: has_bonus,
      query1: query1,
      reg_ref1: reg_ref1,
      reg_d: reg_date,
      last_d: last_date,
      status: status,
      segment: segment,
      segment_upd_t: segment_upd_t,
      first_dep_d: first_dep_date,
      first_dep_sum: first_dep_sum,
      email_unsub_types: email_unsub_types,
      sms_unsub_types: sms_unsub_types,
      cash_real: cash_real,
      cash_user_real: cash_user_real,
      traffic_source: Enum.at(ProjectUser.traffic_sources(), rem(reg_past_days, 4)),
      project_id: project.id,
    })
    |> Ecto.Changeset.put_assoc(:phones, phones)
    |> Repo.insert!
  end

end
