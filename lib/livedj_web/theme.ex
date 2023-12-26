defmodule LivedjWeb.Theme do
  @moduledoc false

  def on_mount(:fetch_theme, _params, _session, socket) do
    {:cont, mount_current_theme(socket)}
  end

  defp mount_current_theme(socket) do
    Phoenix.Component.assign(
      socket,
      :theme,
      Phoenix.LiveView.get_connect_params(socket)["_theme"]
    )
  end
end
