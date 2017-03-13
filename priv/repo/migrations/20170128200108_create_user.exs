defmodule Gt.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION citext;")

    create table(:users) do
      add :email, :citext
      add :permissions, :map
      add :is_admin, :boolean, default: false
      add :locale, :string, default: "ru"
      add :auth, :string, default: "none"
      add :phone, :string
      add :failed_login, :integer, default: 0
      add :enabled, :boolean, default: true
      add :description, :string
      add :notifications, :boolean

      timestamps()
    end

    create index(:users, [:email], unique: true)
  end
end
