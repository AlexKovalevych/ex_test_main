defmodule Gt.Repo.Migrations.CreateCbrRate do
  use Ecto.Migration

  def change do
    create table(:cbr_rates) do
      add :date, :date, null: false
      add :currency, :string, null: false
      add :rate, :float, null: false
    end

    create index(:cbr_rates, [:date, :currency], unique: true)

  end
end
