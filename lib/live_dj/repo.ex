defmodule LiveDj.Repo do
  use Ecto.Repo,
    otp_app: :live_dj,
    adapter: Ecto.Adapters.Postgres
end
