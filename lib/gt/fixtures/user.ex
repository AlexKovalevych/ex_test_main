defmodule Gt.Fixtures.User do
  alias Gt.Repo
  alias Gt.User
  alias Gt.UserSettings
  alias Gt.Project
  import Gt.Auth.Permissions, only: [add: 3]

  @users [
    {
      "alex@example.com",
      "none",
      "06312345678",
      true
    },
    {
      "admin@example.com",
      "sms",
      "06312345678",
      true
    },
    {
      "test@example.com",
      "google",
      "06312345678",
      false
    }
  ]

  def run do
    projects = Repo.all(Project)
    permissions = Application.get_env(:gt, :permissions)
    project_ids = Enum.map(projects, fn project -> project.id end)
    permissions = add(permissions, Map.keys(permissions), project_ids)

    @users
    |> Enum.map(&get_user(&1, permissions))
    |> Enum.each(&Repo.insert!/1)

    1..20
    |> Stream.map(fn i ->
      get_user({"user#{i}@example.com", "none", "06312345678", false}, permissions)
    end)
    |> Stream.each(&Repo.insert!/1)
    |> Enum.into([])
  end

  defp get_user({email, auth, phone, is_admin}, permissions) do
    pass = String.split(email, "@") |> List.first

    user = %{
      permissions: permissions,
      email: email,
      is_admin: is_admin,
      phone: phone,
      auth: auth,
      authorizations: nil,
      password: pass,
    }

    User.new_changeset(%User{}, user)
    |> Ecto.Changeset.put_assoc(:settings,  UserSettings.changeset(%UserSettings{}))
  end

end
