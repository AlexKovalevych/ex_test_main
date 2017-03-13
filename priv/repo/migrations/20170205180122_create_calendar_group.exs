defmodule Gt.Repo.Migrations.CreateCalendarGroup do
  use Ecto.Migration

  def change do
    create table(:calendar_groups) do
      add :name, :string
      add :color, :string

      timestamps()
    end

  end
end
