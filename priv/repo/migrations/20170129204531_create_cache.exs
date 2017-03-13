defmodule Gt.Repo.Migrations.CreateCache do
  use Ecto.Migration

  def change do
    create table(:caches) do
      add :start, :date
      add :end, :date
      add :processed, :integer, default: 0
      add :total, :integer, default: 0
      add :projects, {:array, :int}
      add :active, :boolean, default: false # Means whether cache is processing at this moment
      add :completed, :boolean, default: false
      add :interval, :integer # Interval in days. Used for cron workers only
      add :type, :string # type of cache worker
      add :status, :map

      timestamps()
    end

  end
end
