defmodule Gt.Repo.Migrations.CreateAuthorization do
  use Ecto.Migration

  def change do
    create table(:authorizations) do
      add :provider, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :text
      add :expires_at, :bigint
      add :show_img, :boolean

      timestamps()
    end

    create index(:authorizations, [:provider, :user_id], unique: true)
    create index(:authorizations, [:expires_at])
    create index(:authorizations, [:provider, :token])
  end
end
