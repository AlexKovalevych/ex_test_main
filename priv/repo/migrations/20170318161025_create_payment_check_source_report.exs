defmodule Gt.Repo.Migrations.CreatePaymentCheckSourceReport do
  use Ecto.Migration

  def change do
    create table(:payment_check_source_reports) do
      add :filename, :string, null: false
      add :merchant, :string, null: false
      add :error, :string
      add :from, :date, null: false
      add :to, :date, null: false
      add :currency, :string
      add :in, :map, null: false
      add :out, :map, null: false
      add :fee_in, :map, null: false
      add :fee_out, :map, null: false
      add :chargeback, :map
      add :representment, :map
      add :extra_data, :map
      add :payment_check_id, references(:payment_checks, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:payment_check_source_reports, [:payment_check_id])
  end
end
