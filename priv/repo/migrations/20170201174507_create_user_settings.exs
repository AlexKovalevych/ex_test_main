defmodule Gt.Repo.Migrations.CreateUserSettings do
  use Ecto.Migration

  def change do
    create table(:user_settings) do
      add :dashboard_compare_period, :integer, default: -1
      add :dashboard_period, :string, default: "month"
      add :dashboard_projects, :string, default: "default"
      add :dashboard_sort, :string, default: "inout_sum"

      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

  end
end
