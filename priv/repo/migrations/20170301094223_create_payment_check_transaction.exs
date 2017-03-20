defmodule Gt.Repo.Migrations.CreatePaymentCheckTransaction do
  use Ecto.Migration

  def change do
    create table(:payment_check_transactions) do
      add :ps_trans_id, :string, null: false
      add :one_gamepay_id, :integer
      add :pguid, :string
      add :sum, :float, null: false
      add :fee, :float, null: false, default: 0
      add :currency, :string
      add :fee_currency, :string
      add :date, :naive_datetime, null: false
      add :type, :string
      add :account_id, :string
      add :fee_account_id, :string
      add :state, :string
      add :player_purse, :string
      add :comment, :text
      add :source, :map, null: false
      add :errors, :map
      add :skipped, :string
      add :lang, :string
      add :report_sum, :float
      add :report_currency, :string
      add :payment_check_id, references(:payment_checks, on_delete: :delete_all), null: false
      add :one_gamepay_transaction_id, references(:one_gamepay_transactions, on_delete: :nothing)

      timestamps()
    end

    create index(:payment_check_transactions, [:payment_check_id])
  end
end
