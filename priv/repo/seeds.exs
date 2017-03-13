# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Gt.Repo.insert!(%Gt.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

require Logger
require Gt.Fixture, as: Fixture

alias Gt.Fixtures.{
  Project,
  User,
  ProjectUser,
  Payment,
  Cache,
  CalendarGroup,
  CalendarType,
  CalendarEvent,
  ProjectGame,
  ProjectUserGame,
  PokerGame,
  ProcessedEvent,
  Rate,
  DataSource,
  #PaymentSystem,
  #Visitor
}
import Ecto.Query

Logger.configure([level: :info])

Enum.each([
            Rate,
            DataSource,
            Project,
            User,
            Cache,
            CalendarGroup,
            CalendarType,
            CalendarEvent,
            ProjectUser,
            ProjectGame,
            ProjectUserGame,
            PokerGame,
            ProcessedEvent,
            Payment,
          ], &Fixture.run/1)

Logger.info("Creating user stats")
stats_cache = Gt.Cache |> where([c], c.type == "stats") |> Gt.Repo.one!
Gt.CacheWorker.handle_cast(:stats, %{cache: stats_cache})
Logger.info("Creating vip stats")
vip_cache = Gt.Cache |> where([c], c.type == "vip") |> Gt.Repo.one!
Gt.CacheWorker.handle_cast(:vip, %{cache: vip_cache})
