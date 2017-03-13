defmodule Gt.UserSettings do
  use Gt.Web, :model

  @dashboard_periods ~w(month year days30 months12)

  @dashboard_projects ~w(default partner)

  @dashboard_sort ~w(inout_sum deps_sum wdrs_sum netgaming_sum bets_sum wins_sum first_deps_sum)

  @dashboard_compare_periods -1..-6

  def dashboard_periods(), do: @dashboard_periods

  def dashboard_compare_periods(), do: @dashboard_compare_periods

  schema "user_settings" do
    field :dashboard_compare_period, :integer, default: -1
    field :dashboard_period, :string, default: "month"
    field :dashboard_projects, :string, default: "default"
    field :dashboard_sort, :string, default: "inout_sum"

    belongs_to :user, Gt.User
  end

  @optional_fields ~w(dashboard_compare_period
                      dashboard_period
                      dashboard_projects
                      dashboard_sort)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @optional_fields)
    |> validate_inclusion(:dashboard_period, @dashboard_periods)
    |> validate_inclusion(:dashboard_projects, @dashboard_projects)
    |> validate_inclusion(:dashboard_sort, @dashboard_sort)
    |> validate_inclusion(:dashboard_compare_period, @dashboard_compare_periods)
  end

end
