defmodule Gt.Repo.Migrations.AddVipLevels do
  use Ecto.Migration

  def change do
    alter table(:project_users) do
      remove :vip_levels
      add :vip_1000, :date
      add :vip_1500, :date
      add :vip_2500, :date
      add :vip_5000, :date
    end

  end
end
