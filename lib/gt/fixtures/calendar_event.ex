defmodule Gt.Fixtures.CalendarEvent do
  alias Gt.CalendarType
  alias Gt.CalendarEvent
  alias Gt.Project
  alias Gt.Repo
  alias Gt.User
  import Ecto.Query
  use Timex

  @now Timex.now

  @events [
    {100, 0, 0, 0, 100, 23, 59, 0, 0, ["lt1", "lt2"] },
    {95, 22, 0, 0, 86, 23, 59, 0, 1, ["lt1", "lt2", "lt9"] },
    {90, 0, 0, 0, 90, 23, 59, 0, 4, ["lt1", "cs8", "lt7"] },
    {88, 0, 0, 0, 80, 23, 59, 0, 10, ["cs1"] },
    {80, 0, 0, 0, 74, 23, 59, 0, 2, ["lt3"] },
    {74, 0, 0, 0, 65, 23, 59, 0, 0, ["lt1", "lt2"] },
    {65, 0, 0, 0, 55, 23, 59, 0, 15, ["lt1", "lt2", "lt3"] },
    {54, 0, 0, 0, 54, 23, 59, 0, 13, ["lt1", "lt2", "lt3"] },
    {53, 0, 0, 0, 51, 23, 59, 0, 25, ["cs1", "cs2" ] },
    {53, 0, 0, 0, 50, 23, 59, 0, 9, ["lt6"] },
    {55, 0, 0, 0, 50, 23, 59, 0, 2, ["lt1"] },
    {50, 0, 0, 0, 50, 23, 59, 0, 2, ["lt1", "lt2", "lt3"] },
    {49, 0, 0, 0, 49, 23, 59, 0, 2, ["lt6"] },
    {50, 0, 0, 0, 46, 23, 59, 0, 2, ["cs1", "cs2", "cs3", "cs4"] },
    {45, 0, 0, 0, 45, 23, 59, 0, 2, ["cs1"] },
    {45, 0, 0, 0, 40, 23, 59, 0, 2, ["cs1", "lt1", "lt6"] },
    {39, 0, 0, 0, 30, 23, 59, 0, 2, ["cs1", "cs2", "cs3", "cs4"] },
    {33, 0, 0, 0, 23, 23, 59, 0, 2, ["lt1", "lt2"] },
    {22, 0, 0, 0, 10, 23, 59, 0, 2, ["lt1"] },
    {9, 0, 0, 0, 0, 23, 59, 0, 2, ["lt1", "cs1"] },
    {22, 0, 0, 0, 10, 23, 59, 0, 2, ["lt1"] },
  ]

  def run() do
    user = User
           |> where([u], u.email == "alex@example.com")
           |> Repo.one

    types = CalendarType
            |> order_by([ct], asc: ct.name)
            |> Repo.all

    projects = Project
               |> Repo.all
               |> Enum.map(fn project ->
                 {project.prefix, project}
               end)
               |> Map.new
    @events
    |> Enum.with_index
    |> Enum.map(&get_event(&1, user, types, projects))
    |> Enum.each(&Repo.insert!/1)
  end

  defp get_event({data, i}, user, types, projects) do
    {start_days, start_h, start_m, start_s, end_days, end_h, end_m, end_s, type, project_prefixes} = data
    start_at = @now
               |> Timex.shift(days: -start_days)
               |> Timex.set([{:time, {start_h, start_m, start_s}}])
               |> Timex.to_naive_datetime
    end_at = @now
             |> Timex.shift(days: -end_days)
             |> Timex.set([{:time, {end_h, end_m, end_s}}])
             |> Timex.to_naive_datetime
    project_ids = Enum.map(project_prefixes, fn prefix ->
      Map.get(projects, prefix)
      |> Map.get(:id)
      |> to_string
    end)

    %CalendarEvent{}
    |> CalendarEvent.changeset(%{
      title: "Event ##{i}",
      start_at: start_at,
      end_at: end_at,
      type_id: Enum.at(types, type).id,
      user_id: user.id,
      project_ids: project_ids,
    })
  end

end
