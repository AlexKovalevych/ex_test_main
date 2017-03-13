defmodule Gt.PermissionsView do
  use Gt.Web, :view
  alias Gt.Project
  alias Gt.Repo
  alias Gt.User
  import Gt.Auth.Permissions

  def render("permissions.csv", %{}) do
    headers = [
      dgettext("permissions", "user"),
      dgettext("permissions", "project"),
      dgettext("permissions", "role"),
      dgettext("permissions", "value")
    ]
    projects = Project
               |> Project.order_by_title
               |> Repo.all
    users = Repo.all(User)
    roles = all_roles()
    rows = users
           |> Enum.map(fn user ->
             Enum.map(projects, fn(project) ->
               Enum.map(roles, fn(role) ->
                 [user.email, project.title, role, has(user.permissions, role, project.id)]
               end)
             end)
           end)
           |> Enum.concat
           |> Enum.concat

    [headers | rows]
    |> CSV.encode
    |> Enum.to_list
  end
end
