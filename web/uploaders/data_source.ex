defmodule Gt.Uploaders.DataSource do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]

  @extensions ~w(.csv .txt .json)

  def extensions(), do: @extensions

  # Whitelist file extensions:
  def validate({file, _}) do
    @extensions |> Enum.member?(Path.extname(file.file_name))
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "uploads/data_source/#{scope.id}"
  end

  def local_path(id, filename) do
    Path.join(System.cwd(), "uploads/data_source/#{id}/#{filename}")
  end

end
