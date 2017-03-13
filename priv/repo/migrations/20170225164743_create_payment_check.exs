defmodule Gt.Repo.Migrations.CreatePaymentCheck do
  use Ecto.Migration

  def change do
    create table(:payment_checks) do
      add :files, {:array, :string}, default: []
      add :active, :boolean, default: false, null: false
      add :completed, :boolean, default: false, null: false
      add :processed, :integer
      add :total, :integer
      add :user_id, references(:users, on_delete: :nothing)
      add :payment_system_id, references(:payment_systems, on_delete: :nothing)
      add :status, :map
      add :ps, :map

      timestamps()
    end
    create index(:payment_checks, [:payment_system_id])

  end
end
