defmodule Gt.Repo do
  use Ecto.Repo, otp_app: :gt
  use Kerosene, per_page: 10
end
