defmodule Gt.Repo.Migrations.CreateEcbRate do
  use Ecto.Migration

  def change do
    create table(:ecb_rates) do
      add :date, :date, null: false
      add :currency, :string, null: false
      add :rate, :float, null: false
    end

    create index(:ecb_rates, [:date, :currency], unique: true)

  end
end
