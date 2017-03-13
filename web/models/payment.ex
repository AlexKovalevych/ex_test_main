defmodule Gt.Payment do
  use Gt.Web, :model

  @state_new 0
  @state_approved 1
  @state_failure 2
  @state_cancelled 3

  @type_deposit 1
  @type_withdrawal 2
  @type_bonus 3
  @type_refund 4

  def type(:deposit), do: @type_deposit
  def type(:withdrawal), do: @type_withdrawal
  def type(:bonus), do: @type_bonus
  def type(:refund), do: @type_refund

  def state(:new), do: @state_new
  def state(:approved), do: @state_approved
  def state(:failure), do: @state_failure
  def state(:cancelled), do: @state_cancelled

  def states(), do: [@state_new, @state_approved, @state_failure, @state_cancelled]

  def types(), do: [@type_deposit, @type_withdrawal, @type_bonus, @type_refund]

  schema "payments" do
    field :item_id, :string
    field :date, :naive_datetime
    field :type, :integer
    field :state, :integer
    field :sum, :integer
    field :user_sum, :integer
    field :system, :string
    field :ip, :string
    field :phone, :string
    field :email, :string
    field :info, :map
    field :reason, :string
    field :group_id, :integer
    field :current_balance, :integer
    field :promo_ref, :string
    field :currency, :string
    field :commit_date, :naive_datetime

    belongs_to :project, Gt.Project

    belongs_to :project_user, Gt.ProjectUser
  end

  @required_fields ~w(
    project_id
    project_user_id
    item_id
    date
    type
    state
    sum
  )a

  @optional_fields ~w(
    user_sum
    ip
    phone
    email
    info
    reason
    group_id
    current_balance
    promo_ref
    currency
    system
    commit_date
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:state, states())
    |> validate_inclusion(:type, types())
    |> validate_number(:sum, greater_than_or_equal_to: 0)
  end

  def by_project_item_id(query, project_id, item_id) do
    query
    |> where([pu], pu.project_id == ^project_id and pu.item_id == ^item_id)
  end

  def by_user(query, project_user_id) do
    query |> where([p], p.project_user_id == ^project_user_id)
  end

  def by_period(query, from, to) do
    query
    |> where([p], fragment("date(?) >= ?", p.date, ^from))
    |> where([p], fragment("date(?) <= ?", p.date, ^to))
  end

  def approved(query) do
    query |> where([p], p.state == @state_approved)
  end

  def deposits(query) do
    query
    |> where([p], p.type == @type_deposit)
    |> where([p], p.state == @state_approved)
  end

  def withdrawals(query) do
    query
    |> where([p], p.type == @type_withdrawal)
    |> where([p], p.state == @state_approved)
  end

  @doc """
  Example sql:

  select
    project_id,
    date(date),
    sum(CASE WHEN type = 1 THEN sum ELSE 0 END) as deps_sum,
    sum(CASE WHEN type = 1 THEN 1 ELSE 0 END) as deps_num,
    sum(CASE WHEN type = 2 THEN sum ELSE 0 END) as wdrs_sum,
    sum(CASE WHEN type = 2 THEN 1 ELSE 0 END) as wdrs_num,
    avg(case when type = 1 then sum end) as avg_dep,
    sum(CASE WHEN type = 1 THEN sum ELSE -sum END) as inout_sum,
    sum(1) as inout_num,
    count(distinct(project_user_id)) as transactors,
    (sum(sum) / count(distinct(project_user_id))) as avg_arpu,
    count(distinct CASE WHEN type = 1 THEN project_user_id ELSE null END) as depositors
  from payments
    where state = 1 and type in(1,2) and date(date) >= '2016-01-01' and date(date) <= '2016-02-01' and project_id in(1)
    group by project_id, date(date)
    order by date;
  """
  def dashboard_stats(from, to, project_ids) do
    from(p in __MODULE__,
      select: %{
        project_id: p.project_id,
        date: fragment("date(?)", p.date),
        deps_sum: sum(fragment("CASE WHEN ? = ? THEN ? ELSE 0 END", p.type, @type_deposit, p.sum)),
        deps_num: sum(fragment("CASE WHEN ? = ? THEN 1 ELSE 0 END", p.type, @type_deposit)),
        wdrs_sum: sum(fragment("CASE WHEN ? = ? THEN ? ELSE 0 END", p.type, @type_withdrawal, p.sum)),
        wdrs_num: sum(fragment("CASE WHEN ? = ? THEN 1 ELSE 0 END", p.type, @type_withdrawal)),
        avg_dep: avg(fragment("CASE WHEN ? = ? THEN ? END", p.type, @type_deposit, p.sum)),
        inout_sum: sum(fragment("CASE WHEN ? = ? THEN ? ELSE -? END", p.type, @type_deposit, p.sum, p.sum)),
        inout_num: sum(1),
        transactors: count(fragment("distinct(?)", p.project_user_id)),
        avg_arpu: fragment("sum(?) / count(distinct(?))", p.sum, p.project_user_id),
        depositors: count(fragment("distinct CASE WHEN ? = ? THEN ? ELSE null END", p.type, @type_deposit, p.project_user_id))
      },
      where: p.state == @state_approved
        and p.type in [@type_deposit, @type_withdrawal]
        and fragment("date(?)", p.date) >= ^from
        and fragment("date(?)", p.date) <= ^to
        and p.project_id in ^project_ids,
      group_by: [:project_id, fragment("date(?)", p.date)],
      order_by: fragment("date(?)", p.date)
    )
  end
end
