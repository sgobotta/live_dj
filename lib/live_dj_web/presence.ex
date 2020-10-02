defmodule LiveDjWeb.Presence do
  use Phoenix.Presence,
    otp_app: :live_dj,
    pubsub_server: LiveDj.PubSub
end
