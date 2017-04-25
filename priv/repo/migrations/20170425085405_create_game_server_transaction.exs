defmodule Gt.Repo.Migrations.CreateGameServerTransaction do
  use Ecto.Migration

  def change do
    create table(:game_server_transactions) do
      add :item_id, :string, null: false
      add :date, :naive_datetime, null: false
      add :sum, :integer, null: false
      add :user_sum, :integer, null: false
      add :system, :string
      add :system_id, :integer
      add :status, :string, null: false
      add :status_id, :integer, null: false
      add :pguid, :string

      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:game_server_transactions, [:item_id, :project_id], unique: true)
  end
end
