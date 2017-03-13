defmodule Gt.Repo.Migrations.CreateCalendarEvent do
  use Ecto.Migration

  def change do
    create table(:calendar_events) do
      add :start_at, :naive_datetime, null: false
      add :end_at, :naive_datetime, null: false
      add :title, :string, size: 400
      add :description, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :type_id, references(:calendar_types, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:calendar_event_projects, primary_key: false) do
      add :calendar_event_id, references(:calendar_events), null: false
      add :project_id, references(:projects), null: false
    end

  end

end
