defmodule Gt.Repo.Migrations.CreateProject do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :title, :string
      add :prefix, :string
      add :item_id, :string, null: false
      add :external_id, :string
      add :url, :string, null: false
      add :logo_url, :text
      add :enabled, :boolean, default: false
      add :is_poker, :boolean, default: false
      add :is_partner, :boolean, default: false

      timestamps()
    end

    create index(:projects, [:url], unique: true)
    create index(:projects, [:item_id], unique: true)

  end
end
