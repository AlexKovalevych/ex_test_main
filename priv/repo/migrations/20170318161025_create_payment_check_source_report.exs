defmodule Gt.Repo.Migrations.CreatePaymentCheckSourceReport do
  use Ecto.Migration

  def change do
    create table(:payment_check_source_reports) do
      add :filename, :string, null: false
      add :merchant, :string
      add :error, :string
      add :from, :date
      add :to, :date
      add :currency, :string
      add :in, :map
      add :out, :map
      add :fee_in, :map
      add :fee_out, :map
      add :chargeback, :map
      add :representment, :map
      add :extra_data, :map
      add :payment_check_id, references(:payment_checks, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:payment_check_source_reports, [:payment_check_id])
  end
end
