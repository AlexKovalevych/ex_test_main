defmodule Gt.User do

  @derive {Poison.Encoder, only: [:id, :email, :permissions]}

  @type user :: %__MODULE__{}
  @type auth :: %Gt.Authorization{}

  use Gt.Web, :model
  use AMQP
  alias Gt.Authorization
  alias Gt.UserSettings
  import Gt.Gettext
  import Ecto.Query
  require Logger

  @sms_length 8
  @code_variance 2
  @failed_login_limit 6

  schema "users" do
    field :email, :string, default: ""
    field :permissions, :map, default: %{}
    field :is_admin, :boolean, default: false
    field :locale, :string, default: "ru"
    field :auth, :string, default: "none"
    field :phone, :string
    field :failed_login, :integer, default: 0
    field :enabled, :boolean, default: true
    field :description, :string
    field :notifications, :boolean, default: false
    field :password, :string, virtual: true

    has_many :authorizations, Authorization, on_replace: :delete

    has_one :settings, UserSettings

    timestamps()
  end

  @required_fields ~w(email permissions is_admin locale auth phone enabled)a

  @optional_fields ~w(description failed_login)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, is_new \\ false) do
    required_fields = if is_new, do: @required_fields ++ [:password], else: @required_fields
    struct
    |> cast(params, @required_fields ++ @optional_fields ++ [:password])
    |> cast_assoc(:settings)
    |> validate_required(required_fields)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> validate_length(:password, min: 4)
    |> validate_format(:phone, ~r/^\+?\d{9,15}$/)
    |> unique_constraint(:email)
    |> create_authorizations()
  end

  def new_changeset(struct, params \\ %{}) do
    changeset(struct, params, true)
  end

  defp create_authorizations(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  defp create_authorizations(%Ecto.Changeset{changes: %{password: pass}, valid?: true} = changeset) do
    identity = %Authorization{
      provider: to_string(:identity),
      token: Comeonin.Bcrypt.hashpwsalt(pass),
      expires_at: nil
    }

    sms = %Authorization{
      provider: to_string(:sms),
      token: sms_code(),
      expires_at: nil
    }

    google = %Authorization{
      provider: to_string(:google),
      token: google_code(),
      expires_at: nil,
      show_img: true
    }

    changeset |> Ecto.Changeset.put_assoc(:authorizations, [identity, sms, google])
  end

  defp create_authorizations(%Ecto.Changeset{valid?: true} = changeset) do
    changeset
  end

  @doc """
  Generates sms code of variable length
  from: @sms_length - @code_variance to: @sms_length + @code_variance
  """
  def sms_code do
    code_length = @sms_length - @code_variance + :rand.uniform(@code_variance * 2)
    to_string for _ <- 1..code_length, do: to_string(:rand.uniform(10) - 1)
  end

  @doc """
  Generates random hash of 10 symbols length
  """
  def google_code do
    :crypto.strong_rand_bytes(10) |> Base.encode32
  end

  @doc """
  Returns auth by provider from user
  """
  @spec provider_auth(user, atom) :: {:error, :no_provider} | {:ok, %Authorization{}}
  def provider_auth(user, provider) do
    Enum.reduce_while(user.authorizations, {:error, :no_provider}, fn authorization, acc ->
      if authorization.provider == to_string(provider) do
        {:halt, {:ok, authorization}}
      else
        {:cont, acc}
      end
    end)
  end

  @doc """
  Update user after login
  """
  @spec login(user) :: %Ecto.Changeset{}
  def login(user) do
    changeset(user, %{failed_login: 0})
  end

  @doc """
  Update user after failed login
  """
  @spec login_failed(user) :: %Ecto.Changeset{}
  def login_failed(user) do
    changeset(user, %{failed_login: user.failed_login + 1})
  end

  @doc """
  Returns user from auth or error with reason
  """
  @spec from_auth(%Ueberauth.Auth{provider: :identity}) :: {:error, String.t} | {:ok, user}
  def from_auth(%{provider: :identity} = auth) do
    user = __MODULE__
    |> select([u], u)
    |> preload(:authorizations)
    |> Repo.get_by(email: uid_from_auth(auth))
    case user do
      nil -> {:error, dgettext("login", "invalid_credentials")}
      user ->
        with nil                  <- check_failed_limit(user),
             {:ok, authorization} <- provider_auth(user, auth.provider),
             true                 <- Comeonin.Bcrypt.checkpw(auth.credentials.other.password, authorization.token) do
             login(user) |> Repo.update
        else
          true -> {:error, dgettext("login", "user_disabled")}
          false ->
            login_failed(user) |> Repo.update!
            {:error, dgettext("login", "invalid_credentials")}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc """
  Set show_img field in google auth. Returns list of authorizatios
  """
  @spec set_show_img(user, boolean) :: auth
  def set_show_img(user, value) do
    Authorization
    |> Repo.get_by(user_id: user.id, provider: "google")
    |> Authorization.changeset(%{show_img: value})
  end

  @doc """
  Update token in sms authorization
  """
  @spec update_sms(user) :: auth
  def update_sms(user) do
    Authorization
    |> Repo.get_by(user_id: user.id, provider: "sms")
    |> Authorization.changeset(%{token: sms_code()})
  end

  defp uid_from_auth(auth), do: auth.uid

  @doc """
  Check if user reached limit of failed login and disabled him if he did
  """
  @spec check_failed_limit(user) :: boolean | nil
  def check_failed_limit(user) do
    if user.failed_login >= @failed_login_limit do
      changeset(user, %{enabled: false}) |> Repo.update!
      true
    end
  end

end

defimpl Phoenix.HTML.Safe, for: Gt.User do
  def to_iodata(%Gt.User{email: email}) do
    Plug.HTML.html_escape(email)
  end
end

