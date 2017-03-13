defmodule Gt.Fixtures.Cache do
  alias Gt.Cache
  alias Gt.Project
  alias Gt.Repo
  require Logger
  use Timex

  def run do
    projects = Project
               |> Repo.all
               |> Enum.map(fn project -> project.id end)
    now = Timex.today

    %Cache{type: "stats"}
    |> Cache.changeset(%{
      start: ~D[2003-01-01],
      end: now,
      projects: projects,
    })
    |> Repo.insert!()

    %Cache{type: "vip"}
    |> Cache.changeset(%{
      projects: projects,
    })
    |> Repo.insert!()

    %Cache{type: "consolidated"}
    |> Cache.changeset(%{
      start: ~D[2003-01-01],
      end: now,
      projects: projects,
      interval: 120,
      active: true
    })
    |> Repo.insert!()
  end

end
