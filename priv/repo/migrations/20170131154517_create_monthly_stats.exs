defmodule Gt.Repo.Migrations.CreateMonthlyStats do
  use Ecto.Migration

  def change do
    create table(:monthly_stats) do
      add :date, :date, null: false
      add :inout_sum, :integer, default: 0, null: false
      add :inout_num, :integer, default: 0, null: false
      add :deps_sum, :integer, default: 0, null: false
      add :deps_num, :integer, default: 0, null: false
      add :wdrs_sum, :integer, default: 0, null: false
      add :wdrs_num, :integer, default: 0, null: false
      add :depositors, :integer, default: 0, null: false
      add :first_depositors, :integer, default: 0, null: false
      add :first_deps_sum, :integer, default: 0, null: false
      add :signups, :integer, default: 0, null: false
      add :avg_dep, :float, default: 0.0, null: false
      add :avg_arpu, :float, default: 0.0, null: false
      add :avg_first_dep, :float, default: 0.0, null: false
      add :netgaming_sum, :float, default: 0.0, null: false
      add :bets_sum, :float, default: 0.0, null: false
      add :wins_sum, :float, default: 0.0, null: false
      add :bets_num, :integer, default: 0, null: false
      add :wins_num, :integer, default: 0, null: false
      add :rake_sum, :float, default: 0.0, null: false
      add :transactors, :integer, default: 0, null: false
      add :authorizations, :integer, default: 0, null: false
      add :vip_1000, :integer, default: 0, null: false
      add :vip_1500, :integer, default: 0, null: false
      add :vip_2500, :integer, default: 0, null: false
      add :vip_5000, :integer, default: 0, null: false

      add :project_id, references(:projects, on_delete: :delete_all), null: false
    end

    create index(:monthly_stats, [:date, :project_id], unique: true)

  end
end
