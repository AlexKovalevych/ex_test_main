defmodule Gt.UserLogin do
  use Gt.Web, :model

  @state_work 0
  @state_processed 1
  @state_error 2
  @state_skipped 3

  schema "event_user_logins" do
    field :item_id, :string
    field :processed_at, :naive_datetime
    field :ip, :string
    field :query, :string
    field :data, :map
    field :state_id, :integer
    field :date, :naive_datetime
    field :state, :integer
    field :error, :string

    belongs_to :project, Gt.Project

    belongs_to :project_user, Gt.ProjectUser

    timestamps()

     #*     discriminatorMap={
     #*         "user_active"="GloboTunesBundle\Document\ProcessedEvent\UserActiveData",
     #*         "user_block"="GloboTunesBundle\Document\ProcessedEvent\UserBlockData",
     #*         "user_cashoutcancel"="GloboTunesBundle\Document\ProcessedEvent\UserCashoutCancelData",
     #*         "user_cashoutcomplete"="GloboTunesBundle\Document\ProcessedEvent\UserCashoutCompleteData",
     #*         "user_depositcomplete"="GloboTunesBundle\Document\ProcessedEvent\UserDepositCompleteData",
     #*         "user_depositerror"="GloboTunesBundle\Document\ProcessedEvent\UserDepositErrorData",
     #*         "user_emailchanged"="GloboTunesBundle\Document\ProcessedEvent\UserEmailChangedData",
     #*         "user_login"="GloboTunesBundle\Document\ProcessedEvent\UserLoginData",
     #*         "user_register"="GloboTunesBundle\Document\ProcessedEvent\UserRegisterData",
     #*         "user_remindpassword"="GloboTunesBundle\Document\ProcessedEvent\UserRemindPasswordData",
     #*         "user_winjackpot"="GloboTunesBundle\Document\ProcessedEvent\UserWinjackpotData",
     #*     },

  end

  @required_fields ~w(
    item_id
    state_id
    date
  )a

  @optional_fields ~w(processed_at data state error ip query)a

  def state_options(), do: [@state_work, @state_processed, @state_error, @state_skipped]

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_inclusion(:state_id, state_options())
    |> validate_required(@required_fields)
  end

  def authorizations_by_period(from, to, project_ids) do
    from(ul in __MODULE__,
         select: %{
           project_id: ul.project_id,
           date: fragment("date(?)", ul.date),
           authorizations: sum(1)
         },
         where: fragment("date(?) between ? and ?", ul.date, ^from, ^to) and ul.project_id in ^project_ids,
         group_by: [ul.project_id, fragment("date(?)", ul.date)])
  end

end

defmodule Gt.UserLoginData do
  use Gt.Web, :model

  embedded_schema do
    #field :event_id, :string
    #field :time, :integer
    field :ip, :string
    field :query, :string
  end

  @required_fields ~w(ip)a

  @optional_fields ~w(query)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:ip, ~r/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
  end
end
