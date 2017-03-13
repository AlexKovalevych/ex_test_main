defmodule Gt.Repo.Migrations.CreatePokerGame do
  use Ecto.Migration

  def change do
    create table(:poker_games, primary_key: false) do
      add :id, :string, primary_key: true
      add :buy_in, :float
      add :user_buy_in, :float
      add :currency, :string
      add :wdr, :float
      add :user_rake, :float
      add :rake_sum, :float
      add :rebuy_in, :float
      add :session_id, :string
      add :session_type, :string
      add :date, :naive_datetime
      add :total_bet, :float
      add :total_payment, :float

      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :project_user_id, references(:project_users, on_delete: :delete_all), null: false
    end

  end
end
