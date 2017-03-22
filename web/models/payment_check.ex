defmodule Gt.PaymentCheck do
  use Gt.Web, :model

  schema "payment_checks" do
    field :files, {:array, :string}, default: []
    field :active, :boolean, default: false
    field :completed, :boolean, default: false
    field :processed, :integer, default: 0
    field :total, :integer, default: 0

    belongs_to :user, Gt.User

    belongs_to :payment_system, Gt.PaymentSystem

    embeds_one :status, Gt.WorkerStatus, on_replace: :delete

    has_many :source_reports, Gt.PaymentCheckSourceReport, on_replace: :delete

    field :ps, :map

    timestamps()
  end

  @required_fields ~w(payment_system_id user_id)a

  @optional_fields ~w(active completed processed total)

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_files(params)
  end

  defimpl Poison.Encoder, for: __MODULE__ do
    def encode(%{id: id, total: total, processed: processed, status: status} = payment_check, options) do
      Poison.encode!(%{
                       id: id,
                       active: Gt.PaymentCheck.is_started(payment_check),
                       total: total,
                       processed: processed,
                       status: status
                     }, options)
    end
  end

  def is_started(payment_check) do
    case payment_check.id && Gt.PaymentCheckRegistry.find(payment_check.id, :pid) do
      nil -> false
      _ -> true
    end
  end

  def clear_state(payment_check) do
    payment_check
    |> Repo.preload(:source_reports)
    |> changeset(%{
                total: 0,
                processed: 0,
                skipped: 0,
                active: true,
                completed: false,
              })
    |> put_assoc(:source_reports, [])
    |> put_embed(:status, nil)
    |> Repo.update!
  end

  defp validate_files(changeset, params) do
    files = Map.get(params, "files", changeset.data.files)
            |> Enum.filter(fn file ->
              cond do
                is_bitstring(file) -> true
                %Plug.Upload{filename: filename} = file ->
                  Enum.member?(Gt.Uploaders.PaymentCheck.extensions(), Path.extname(filename))
              end
            end)

    if !Enum.empty?(files) do
      changeset
    else
      add_error(changeset, :files, "can't be blank", [validation: :required])
    end
  end

  def is_completed(payment_check) do
    payment_check.status && payment_check.status.state == ":normal"
  end

end
