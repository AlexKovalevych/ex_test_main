defmodule Gt.Repo.Migrations.CreateUserMonthlyStats do
  use Ecto.Migration

  def change do
    create table(:user_monthly_stats) do
      add :date, :date
      add :deps, :integer, default: 0
      add :wdrs, :integer, default: 0
      add :deps_sum, :integer, default: 0
      add :wdrs_sum, :integer, default: 0

      add :project_user_id, references(:project_users, on_delete: :delete_all), null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
    end

    create index(:user_monthly_stats, [:project_user_id, :project_id, :date], unique: true)

  end
end
