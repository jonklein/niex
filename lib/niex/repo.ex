defmodule Niex.Repo do
  use Ecto.Repo,
    otp_app: :niex,
    adapter: Ecto.Adapters.Postgres
end
