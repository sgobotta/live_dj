defmodule Livedj.Repo do
  use Ecto.Repo,
    otp_app: :livedj,
    adapter: Ecto.Adapters.Postgres
end
