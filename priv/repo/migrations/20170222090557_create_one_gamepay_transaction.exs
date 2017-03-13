defmodule Gt.Repo.Migrations.CreateOneGamepayTransaction do
  use Ecto.Migration

  def change do
    create table(:one_gamepay_transactions) do
      add :trans_id, :integer, null: false
      add :ps_trans_id, :string
      add :project_trans_id, :string
      add :ps_name, :string
      add :payment_instrument_name, :string
      add :status, :string
      add :date, :naive_datetime, null: false
      add :sum, :integer, null: false
      add :currency, :string
      add :channel_sum, :integer
      add :channel_currency, :string
      add :site_url, :string, null: false
      add :processor_code_description, :string
      add :rate, :float
      add :transaction_type, :string
      add :merchant, :string

      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:one_gamepay_transactions, [:trans_id, :project_id], unique: true)

  end
end
