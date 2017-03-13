defmodule Gt.Repo.Migrations.CreateCalendarType do
  use Ecto.Migration

  def change do
    create table(:calendar_types) do
      add :name, :string
      add :group_id, references(:calendar_groups, on_delete: :delete_all), null: false

      timestamps()
    end
  end

end
