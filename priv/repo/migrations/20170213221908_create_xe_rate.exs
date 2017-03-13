defmodule Gt.Repo.Migrations.CreateXeRate do
  use Ecto.Migration

  def change do
    create table(:xe_rates) do
      add :date, :date, null: false
      add :currency, :string, null: false
      add :rate, :float, null: false
    end

    create index(:xe_rates, [:date, :currency], unique: true)

  end
end
