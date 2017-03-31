defmodule Gt.Repo.Migrations.CreateProjectUser do
  use Ecto.Migration

  def change do
    create table(:project_users) do
      add :item_id, :string, null: false
      add :email, :string
      add :email_hash, :string
      add :email_encrypted, :text
      add :email_valid, :integer
      add :email_not_found, :boolean
      add :email_confirmed, :boolean
      add :login, :string
      add :nick, :string
      add :phone, :string
      add :phone_valid, :integer
      add :first_name, :string
      add :last_name, :string
      add :lang, :string
      add :sex, :integer
      add :cash_real, :integer
      add :cash_user_real, :integer
      add :cash_fun, :integer
      add :cash_bonus, :integer
      add :currency, :string
      add :birthday, :string
      add :is_active, :boolean
      add :has_bonus, :boolean
      add :query1, :string
      add :reg_ip, :string
      add :reg_d, :naive_datetime, null: false
      add :reg_ref1, :string
      add :last_d, :naive_datetime
      add :status, :string
      add :segment, :integer
      add :segment_upd_t, :integer
      add :first_dep_d, :naive_datetime
      add :first_dep_sum, :integer
      add :second_dep_d, :naive_datetime
      add :second_dep_sum, :integer
      add :third_dep_d, :naive_datetime
      add :third_dep_sum, :integer
      add :first_wdr_d, :naive_datetime
      add :first_wdr_sum, :integer
      add :email_unsub_types, :map
      add :sms_unsub_types, :map
      add :last_dep_d, :naive_datetime
      add :remind_code, :string
      add :glow_id, :string
      add :donor, :string
      add :vip_levels, :map
      add :social_network, :string
      add :social_network_url, :string
      add :deps, :integer, default: 0
      add :wdrs, :integer, default: 0
      add :deps_sum, :integer, default: 0
      add :wdrs_sum, :integer, default: 0
      add :traffic_source, :string

      add :project_id, references(:projects, on_delete: :delete_all), null: false
    end

    create index(:project_users, [:item_id, :project_id], unique: true)

  end
end
