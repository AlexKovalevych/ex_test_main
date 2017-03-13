defmodule Gt.Repo.Migrations.CreateRefCode do
  use Ecto.Migration

  def change do
    create table(:ref_codes) do
      add :date, :date, null: false
      add :code, :string, null: false

      add :project_user_id, references(:project_users, on_delete: :delete_all), null: false
    end

    create index(:ref_codes, [:date, :code, :project_user_id], unique: true)

  end
end
