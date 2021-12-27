defmodule LiveDjWeb.Presence do
  @moduledoc false

  use Phoenix.Presence,
    otp_app: :live_dj,
    pubsub_server: LiveDj.PubSub
end
