defmodule Gt.Repo.Migrations.CreatePhone do
  use Ecto.Migration

  def change do
    create table(:phones) do
      add :number, :string
      add :type, :integer
      add :valid, :integer
      add :manual_validation, :boolean

      add :project_user_id, references(:project_users, on_delete: :delete_all), null: false
    end
  end

end
