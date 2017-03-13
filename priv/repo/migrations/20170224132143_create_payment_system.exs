defmodule Gt.Repo.Migrations.CreatePaymentSystem do
  use Ecto.Migration

  def change do
    create table(:payment_systems) do
      add :name, :string
      add :script, :string
      add :fields, :map
      add :csv, :map
      add :one_gamepay, :map
      add :fee, :map
      add :report, :map

      timestamps()
    end

  end
end
