defmodule Gt.UserTest do
  use Gt.ModelCase

  alias Gt.User

  @valid_attrs %{auth: "some content", description: "some content", email: "some content", enabled: true, failed_login: 42, google_secret: "some content", is_admin: true, locale: "some content", notifications: true, password: "some content", permissions: %{}, phone: "some content", settings: %{}, show_google_code: true, sms_code: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
