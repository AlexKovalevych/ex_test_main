defmodule Gt.Uploaders.PaymentCheck do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]

  @extensions ~w(.csv .zip .xls .xlsx)

  def extensions(), do: @extensions

  # Whitelist file extensions:
  def validate({file, _}) do
    @extensions |> Enum.member?(Path.extname(file.file_name))
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "uploads/payment_check/#{scope.id}"
  end

  def local_path(id, filename) do
    Path.join(System.cwd(), "uploads/payment_check/#{id}/#{filename}")
  end

end
