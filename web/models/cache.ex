defmodule Gt.Cache do
  use Gt.Web, :model

  @types ["consolidated", "stats", "vip"]

  schema "caches" do
    field :start, :date
    field :end, :date
    field :processed, :integer, default: 0
    field :total, :integer, default: 0
    field :projects, {:array, :integer}
    field :active, :boolean, default: false # Means whether cache is processing at this moment
    field :completed, :boolean, default: false
    field :interval, :integer # Interval in days. Used for cron workers only
    field :type, :string # type of cache worker
    embeds_one :status, Gt.WorkerStatus, on_replace: :delete

    timestamps()
  end

  def types do
    @types
  end

  def is_started(cache) do
    case cache.id && Gt.CacheRegistry.find(cache.id, :pid) do
      nil -> false
      _ -> true
    end
  end

  defimpl Poison.Encoder, for: __MODULE__ do
    def encode(%{id: id, total: total, processed: processed, status: status} = cache, options) do
      Poison.encode!(%{
                       id: id,
                       active: Gt.Cache.is_started(cache),
                       total: total,
                       processed: processed,
                       status: status
                     }, options)
    end
  end

  def clear_state(cache) do
    changeset(cache, %{
                total: 0,
                processed: 0,
                active: true,
                completed: false
              })
    |> put_embed(:status, nil)
    |> Repo.update!
  end

  def changeset(struct, params \\ %{})

  def changeset(%__MODULE__{type: "consolidated"} = struct, params) do
    required_fields = ~w(start end projects type)a
    optional_fields = ~w(processed total interval active completed)a
    struct
    |> cast(params, required_fields ++ optional_fields)
    |> cast_embed(:status)
    |> validate_required(required_fields)
    |> validate_inclusion(:type, @types)
  end

  def changeset(%__MODULE__{type: "vip"} = struct, params) do
    required_fields = ~w(projects type)a
    optional_fields = ~w(processed total active completed)a
    struct
    |> cast(params, required_fields ++ optional_fields)
    |> cast_embed(:status)
    |> validate_required(required_fields)
    |> validate_inclusion(:type, @types)
  end

  def changeset(%__MODULE__{type: "stats"} = struct, params) do
    required_fields = ~w(start end projects type)a
    optional_fields = ~w(processed total active completed)a
    struct
    |> cast(params, required_fields ++ optional_fields)
    |> cast_embed(:status)
    |> validate_required(required_fields)
    |> validate_inclusion(:type, @types)
  end

end
