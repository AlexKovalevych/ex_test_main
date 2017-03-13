defmodule Gt.PokerGame do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :id

  schema "poker_games" do
    field :buy_in, :float
    field :user_buy_in, :float
    field :currency, :string
    field :wdr, :float
    field :user_rake, :float
    field :rake_sum, :float
    field :rebuy_in, :float
    field :session_id, :string
    field :session_type, :string
    field :date, :naive_datetime
    field :total_bet, :float
    field :total_payment, :float

    belongs_to :project, Gt.Project
    belongs_to :project_user, Gt.ProjectUser
  end

  @required_fields ~w(
    project_id
    project_user_id
    buy_in
    user_buy_in
    currency
    wdr
    user_rake
    rake_sum
    rebuy_in
    session_id
    session_type
    date
    total_bet
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  def generate_id(data) do
    data = "#{data.currency}#{data.session_id}#{data.session_type}#{data.date}#{data.project_user_id}#{data.project_id}"
    :crypto.hash(:sha, data) |> Base.encode16(case: :lower)
  end

  def rake(from, to, project_ids) do
    from(pg in __MODULE__,
         select: %{
           project_id: pg.project_id,
           date: fragment("date(?)", pg.date),
           rake_sum: sum(pg.rake_sum)
         },
         where: fragment("date(?) between ? and ?", pg.date, ^from, ^to) and pg.project_id in ^project_ids,
         group_by: [pg.project_id, fragment("date(?)", pg.date)])
  end

end
