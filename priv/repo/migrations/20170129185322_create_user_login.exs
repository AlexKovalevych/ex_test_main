defmodule Gt.Repo.Migrations.CreateUserLogin do
  use Ecto.Migration

  def change do
    create table(:event_user_logins) do
      add :item_id, :string
      add :processed_at, :naive_datetime
      add :ip, :string
      add :query, :string
      add :data, :map
      add :state_id, :integer
      add :date, :naive_datetime
      add :state, :integer
      add :error, :string

      add :project_id, references(:projects, on_delete: :delete_all), null: false

      add :project_user_id, references(:project_users, on_delete: :delete_all), null: false

      timestamps()
    end

  end
end
