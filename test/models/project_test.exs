defmodule Gt.ProjectTest do
  use Gt.ModelCase

  alias Gt.Project

  @valid_attrs %{enabled: true, external_id: "some content", is_partner: true, is_poker: true, item_id: "some content", logo_url: "some content", prefix: "some content", title: "some content", url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Project.changeset(%Project{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Project.changeset(%Project{}, @invalid_attrs)
    refute changeset.valid?
  end
end
