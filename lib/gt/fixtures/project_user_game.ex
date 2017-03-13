defmodule Gt.Fixtures.ProjectUserGame do
  use Timex
  alias Gt.Repo
  alias Gt.{ProjectUserGame, Project, ProjectGame, ProjectUser}
  import Ecto.Query

  def run do
    data = File.read! Path.join(__DIR__, "project_user_games.json")
    project_user_games = Poison.decode!(data)
    projects = Project
               |> Repo.all
               |> Enum.reduce(%{}, fn (project, acc) ->
                 Map.put(acc, project.prefix, project)
               end)

    now = Timex.now
    ParallelStream.map(project_user_games, fn data ->
      [
        hours,
        minutes,
        seconds,
        days,
        user_bets,
        bets_sum,
        bets_num,
        currency,
        game_ref,
        project_prefix,
        user_id,
        user_wins,
        wins_sum,
        wins_num
      ] = data

      project = projects[project_prefix]
      date = now
             |> Timex.shift(days: -days)
             |> Timex.set([{:time, {hours, minutes, seconds}}])
             |> Timex.to_naive_datetime()

      user = ProjectUser
             |> where([pu], pu.project_id == ^project.id)
             |> where([pu], pu.item_id == ^user_id)
             |> Repo.one
      game = ProjectGame
             |> where([pg], pg.project_id == ^project.id)
             |> where([pg], pg.name == ^game_ref)
             |> limit(1)
             |> Repo.one

      changeset = ProjectUserGame.changeset(%ProjectUserGame{}, %{
                                  user_bets: user_bets,
                                  bets_sum: bets_sum,
                                  bets_num: bets_num,
                                  currency: currency,
                                  date: date,
                                  game_ref: game_ref,
                                  user_wins: user_wins,
                                  wins_sum: wins_sum,
                                  wins_num: wins_num,
                                  project_id: project.id,
                                  project_user_id: user.id,
                                  project_game_id: game.id,
                                })

      changeset
      |> Ecto.Changeset.put_change(:id, ProjectUserGame.generate_id(Ecto.Changeset.apply_changes(changeset)))
      |> Repo.insert!
    end) |> Enum.to_list
  end

end
