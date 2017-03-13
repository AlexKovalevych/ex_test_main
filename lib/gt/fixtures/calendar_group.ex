defmodule Gt.Fixtures.CalendarGroup do
  alias Gt.Repo
  alias Gt.CalendarGroup

  @groups [
    {"Внутренние акции", "#40e6ff"},
    {"Закупка траффика", "#68ff2e"},
    {"Технические изменения", "#ff3dfa"},
    {"Технические проблемы", "#fd3d3d"},
    {"Промо", "#d6d905"},
    {"Прочее", "#e1e1e1"},
  ]

  def run() do
    @groups
    |> Enum.map(&get_group/1)
    |> Enum.each(&Repo.insert!/1)
  end

  defp get_group({name, color}) do
    CalendarGroup.changeset(%CalendarGroup{}, %{
                              name: name,
                              color: color
                            })
  end
end
