defmodule Gt.DataSource do
  use Gt.Web, :model
  use Arc.Ecto.Schema

  schema "data_sources" do
    field :name, :string
    field :active, :boolean, default: false
    field :completed, :boolean, default: false
    field :processed, :integer, default: 0
    field :total, :integer, default: 0
    field :type, :string

    field :files, {:array, :string}, default: []
    field :start_at, :date
    field :end_at, :date
    field :interval, :integer
    field :host, :string
    field :subtypes, {:array, :string}
    field :subtype, :string
    field :login, :string
    field :password, :string
    field :encryption, :boolean, default: true
    field :mailbox, :string
    field :port, :integer
    field :separator, :string, default: "comma"
    field :double_qoute, :string, default: "double_qoute"

    embeds_one :status, Gt.WorkerStatus, on_replace: :delete

    belongs_to :project, Gt.Project

    timestamps()
  end

  @separators ~w(comma tab colon pipe space semicolon)

  @double_qoutes ~w(double_qoute single_qoute)

  def separators(), do: @separators

  def double_qoutes(), do: @double_qoutes

  @types ~w(rate
            pomadorro
            one_gamepay_request
            one_gamepay)

  @pomadorro_types ~w(casino_bonuses
                      casino_games
                      casino_invoices
                      casino_users
                      poker_bonuses
                      poker_games_raw)

  @rates_types ~w(xe cbr ecb)

  def pomadorro_types(), do: @pomadorro_types

  def rates_types(), do: @rates_types

  # Common fields
  @required_fields ~w(name)a

  @optional_fields ~w(active completed total processed)a

  # Rates
  @optional_rates ~w(subtype start_at end_at interval host)a

  # Pomadorro
  @required_pomadorro ~w(project_id)a

  @optional_pomadorro ~w(subtypes start_at end_at interval host)a

  # One gamepay request
  @required_one_gamepay_request ~w(start_at end_at host login password)a

  # One gamepay
  @required_one_gamepay ~w(separator double_qoute)a

  @required_one_gamepay_api ~w(host mailbox password port)a

  @optional_one_gamepay ~w(encryption)a

  def is_started(data_source) do
    case data_source.id && Gt.DataSourceRegistry.find(data_source.id, :pid) do
      nil -> false
      _ -> true
    end
  end

  defimpl Poison.Encoder, for: __MODULE__ do
    def encode(%{id: id, total: total, processed: processed, status: status} = data_source, options) do
      Poison.encode!(%{
                       id: id,
                       active: Gt.DataSource.is_started(data_source),
                       total: total,
                       processed: processed,
                       status: status
                     }, options)
    end
  end

  def clear_state(data_source) do
    changeset(data_source, %{
                total: 0,
                processed: 0,
                active: true,
                completed: false,
              })
    |> put_embed(:status, nil)
    |> Repo.update!
  end

  def changeset(struct, params \\ %{}) do
    changeset = struct
    |> cast(params, [:type])
    |> cast_embed(:status)
    |> validate_required([:type])
    |> validate_inclusion(:type, @types)

    if changeset.valid?, do: apply_changes(changeset) |> changeset_type(params), else: changeset
  end

  defp changeset_type(%{type: "rates"} = struct, params) do
    struct = struct
             |> cast(params, @required_fields ++ @optional_fields)
             |> validate_required(@required_fields)

    if Map.get(params, "is_files", false) do
      struct |> validate_files(params)
    else
      struct
      |> cast(params, @optional_rates)
      |> validate_inclusion(:subtype, @rates_types)
    end
  end

  defp changeset_type(%{type: "pomadorro"} = struct, params) do
    struct = struct
             |> cast(params, @required_fields ++ @optional_fields)
             |> validate_required(@required_fields)

    if Map.get(params, "is_files") do
      struct
      |> validate_files(params)
      |> cast(params, @required_pomadorro ++ ~w(subtype)a)
      |> validate_required(@required_pomadorro ++ ~w(subtype)a)
      |> validate_inclusion(:subtype, @pomadorro_types)
    else
      struct
      |> cast(params, @required_pomadorro ++ @optional_pomadorro)
      |> validate_required(@required_pomadorro)
      |> validate_subset(:subtypes, @pomadorro_types)
    end
  end

  defp changeset_type(%{type: "one_gamepay_request"} = struct, params) do
    struct
    |> cast(params, @required_fields ++ @required_one_gamepay_request ++ @optional_fields)
    |> validate_required(@required_fields ++ @required_one_gamepay_request)
  end

  defp changeset_type(%{type: "one_gamepay"} = struct, params) do
    struct = struct
             |> cast(params, @required_fields ++ @required_one_gamepay ++ @optional_fields)
             |> validate_required(@required_fields)
             |> validate_inclusion(:separator, @separators)
             |> validate_inclusion(:double_qoute, @double_qoutes)

    if Map.get(params, "is_files", !Enum.empty?(apply_changes(struct).files)) do
      struct |> validate_files(params)
    else
      struct
      |> cast(params, @required_one_gamepay_api ++ @optional_one_gamepay)
      |> validate_required(@required_one_gamepay)
    end
  end

  defp validate_files(changeset, params) do
    files = Map.get(params, "files", changeset.data.files)
            |> Enum.filter(fn file ->
              cond do
                is_bitstring(file) -> true
                %Plug.Upload{filename: filename} = file ->
                  Enum.member?(Gt.Uploaders.DataSource.extensions(), Path.extname(filename))
              end
            end)

    if !Enum.empty?(files) do
      changeset
    else
      add_error(changeset, :files, "can't be blank", [validation: :required])
    end
  end

end
