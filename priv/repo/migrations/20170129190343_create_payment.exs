defmodule Gt.Repo.Migrations.CreatePayment do
  use Ecto.Migration

  def change do
    create table(:payments) do
      add :item_id, :string
      add :date, :naive_datetime
      add :type, :integer
      add :state, :integer
      add :sum, :integer
      add :user_sum, :integer
      add :system, :string
      add :ip, :string
      add :phone, :string
      add :email, :string
      add :info, :map
      add :reason, :string
      add :group_id, :integer
      add :current_balance, :integer
      add :promo_ref, :string
      add :currency, :string
      add :commit_date, :naive_datetime
      add :traffic_source, :string

      add :project_id, references(:projects, on_delete: :delete_all), null: false

      add :project_user_id, references(:project_users, on_delete: :delete_all), null: false
    end

    create index(:payments, [:project_user_id, :type, :state, :date])
    create index(:payments, [:project_id, :item_id])
  end

end
