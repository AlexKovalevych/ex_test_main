defmodule Gt.Repo.Migrations.CreateDataSource do
  use Ecto.Migration

  def change do
    create table(:data_sources) do
      add :name, :string
      add :active, :boolean, default: false, null: false
      add :completed, :boolean, default: false, null: false
      add :status, :map
      add :type, :string, null: false
      add :start_at, :date
      add :end_at, :date
      add :interval, :integer
      add :host, :string
      add :subtypes, {:array, :string}
      add :subtype, :string
      add :login, :string
      add :password, :string
      add :encryption, :boolean
      add :mailbox, :string
      add :port, :integer
      add :separator, :string
      add :double_qoute, :string
      add :files, {:array, :string}, default: []
      add :processed, :integer, default: 0
      add :total, :integer, default: 0
      add :uri, :string
      add :client, :string
      add :private_key, :string
      add :wl_host, :string
      add :divide_by_100, :boolean

      timestamps()

      add :project_id, references(:projects, on_delete: :delete_all)
    end

  end
end
