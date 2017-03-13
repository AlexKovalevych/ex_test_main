defmodule Gt.Fixtures.PokerGame do
  alias Gt.Repo
  alias Gt.{Project, PokerGame, ProjectUser}
  import Ecto.Query
  use Timex

  def run do
    data = File.read! Path.join(__DIR__, "poker_games.json")
    project = Project
              |> where([p], p.title == "Loto 6")
              |> Repo.one
    now = Timex.now

    data
    |> Poison.decode!
    |> ParallelStream.map(fn data ->
      [
        days,
        hours,
        minutes,
        seconds,
        _,
        _,
        _,
        _,
        buy_in,
        user_buy_in,
        currency,
        wdr,
        user_rake,
        rake_sum,
        rebuy_in,
        session_id,
        session_type,
        total_bet,
        user_item_id
      ] = data
      date = now
             |> Timex.shift(days: -days)
             |> Timex.set([{:time, {hours, minutes, seconds}}])
             |> Timex.to_naive_datetime()
      user = ProjectUser
             |> where([pu], pu.project_id == ^project.id)
             |> where([pu], pu.item_id == ^user_item_id)
             |> Repo.one

      changeset = PokerGame.changeset(%PokerGame{}, %{
                                        buy_in: buy_in,
                                        user_buy_in: user_buy_in,
                                        currency: currency,
                                        wdr: wdr,
                                        user_rake: user_rake,
                                        rake_sum: rake_sum,
                                        rebuy_in: rebuy_in,
                                        session_id: session_id,
                                        session_type: session_type,
                                        date: date,
                                        total_bet: total_bet,
                                        project_id: project.id,
                                        project_user_id: user.id,
                                      })

      changeset
      |> Ecto.Changeset.put_change(:id, PokerGame.generate_id(Ecto.Changeset.apply_changes(changeset)))
      |> Repo.insert!
    end) |> Enum.to_list
  end

end
