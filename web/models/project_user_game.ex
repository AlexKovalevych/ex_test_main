defmodule Gt.ProjectUserGame do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :id

  schema "project_user_games" do
    field :user_bets, :integer
    field :bets_sum, :float
    field :bets_num, :integer
    field :currency, :string
    field :date, :naive_datetime
    field :game_ref, :string
    field :user_wins, :integer
    field :wins_sum, :float
    field :wins_num, :integer
    field :is_risk, :boolean, default: false

    belongs_to :project, Gt.Project
    belongs_to :project_user, Gt.ProjectUser
    belongs_to :project_game, Gt.ProjectGame
  end

  @required_fields ~w(
    project_id
    project_user_id
    project_game_id
    user_bets
    bets_sum
    bets_num
    currency
    date
    game_ref
    user_wins
    wins_sum
    wins_num
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  def generate_id(data) do
    data = "#{data.currency}#{data.date}#{data.game_ref}#{data.project_user_id}#{data.project_id}"
    :crypto.hash(:sha, data) |> Base.encode16(case: :lower)
  end

  def netgaming(from, to, project_ids) do
    from(pug in __MODULE__,
         select: %{
           project_id: pug.project_id,
           date: fragment("date(?)", pug.date),
           bets_num: sum(pug.bets_num),
           bets_sum: sum(pug.bets_sum),
           wins_num: sum(pug.wins_num),
           wins_sum: sum(pug.wins_sum),
           netgaming_sum: fragment("sum(?) - sum(?)", pug.bets_sum, pug.wins_sum)
         },
         where: fragment("date(?) between ? and ?", pug.date, ^from, ^to) and pug.project_id in ^project_ids,
         group_by: [pug.project_id, fragment("date(?)", pug.date)])
  end

end
