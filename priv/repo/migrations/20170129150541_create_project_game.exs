defmodule Gt.Repo.Migrations.CreateProjectGame do
  use Ecto.Migration

  def change do
    create table(:project_games) do
      add :name, :string
      add :item_id, :string
      add :is_mobile, :boolean, default: false
      add :is_demo, :boolean, default: false
      add :is_risk, :boolean, default: false

      add :project_id, references(:projects, on_delete: :delete_all), null: false
    end

    create index(:project_games, [:name, :project_id])

  end
end
