defmodule Gt.Project do

  @derive {Poison.Encoder, only: [:id, :title]}

  use Gt.Web, :model
  alias Gt.Auth.Permissions

  schema "projects" do
    field :title, :string
    field :prefix, :string
    field :item_id, :string
    field :external_id, :string
    field :url, :string
    field :logo_url, :string
    field :enabled, :boolean, default: false
    field :is_poker, :boolean, default: false
    field :is_partner, :boolean, default: false

    timestamps()
  end

  @required_fields ~w(title item_id url enabled is_poker is_partner)a

  @optional_fields ~w(prefix external_id logo_url)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:url, ~r/^https?:\/\/[-\w\.\d]+/)
  end

  def options(query \\ __MODULE__, allowed_ids \\ nil) do
    if allowed_ids do
      query |> where([p], p.id in ^allowed_ids)
    else
      query
    end
    |> order_by_title
    |> Repo.all
    |> Enum.into(%{}, fn project -> {project.title, project.id} end)
  end

  def by_item_id(query, item_id) do
    query |> where([p], p.item_id == ^item_id)
  end

  def by_url(query, nil) do
    query |> where([p], is_nil(p.url))
  end

  def by_url(query, url) do
    query |> where([p], p.url == ^url)
  end

  def allowed(user, permission) do
    Permissions.get(user.permissions, permission) |> Enum.map(&String.to_integer/1)
  end

  def order_by_title(query) do
    query |> order_by([p], fragment("? collate \"C\"", p.title))
  end

end

defimpl Phoenix.HTML.Safe, for: Gt.Project do
  def to_iodata(%Gt.Project{title: title}) do
    Plug.HTML.html_escape(title)
  end
end
