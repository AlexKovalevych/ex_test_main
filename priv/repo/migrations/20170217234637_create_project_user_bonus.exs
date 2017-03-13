defmodule Gt.Repo.Migrations.CreateProjectUserBonus do
  use Ecto.Migration

  def change do
    create table(:project_user_bonuses, primary_key: false) do
      add :id, :string, primary_key: true
      add :date, :naive_datetime
      add :amount, :float
      add :currency, :string
      add :type, :string
      add :project_user_id, references(:project_users, on_delete: :nothing)
      add :project_id, references(:projects, on_delete: :nothing)

      timestamps()
    end

  end
end
