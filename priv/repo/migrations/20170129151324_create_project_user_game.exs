defmodule Gt.Repo.Migrations.CreateProjectUserGame do
  use Ecto.Migration

  def change do
    create table(:project_user_games, primary_key: false) do
      add :id, :string, primary_key: true
      add :user_bets, :integer
      add :bets_sum, :float
      add :bets_num, :integer
      add :currency, :string
      add :date, :naive_datetime
      add :game_ref, :string
      add :user_wins, :integer
      add :wins_sum, :float
      add :wins_num, :integer
      add :is_risk, :boolean, default: false

      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :project_user_id, references(:project_users, on_delete: :delete_all), null: false
      add :project_game_id, references(:project_games, on_delete: :delete_all), null: false
    end

  end
end
