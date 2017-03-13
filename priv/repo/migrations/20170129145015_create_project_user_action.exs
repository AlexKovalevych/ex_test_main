defmodule Gt.Repo.Migrations.CreateProjectUserAction do
  use Ecto.Migration

  def change do
    create table(:user_actions) do
      add :dep1, :map
      add :dep2, :map
      add :dep3, :map
      add :dep4, :map
      add :game1, :map
      add :game2, :map
      add :game3, :map

      add :project_user_id, references(:project_users, on_delete: :delete_all), null: false
    end

  end
end
