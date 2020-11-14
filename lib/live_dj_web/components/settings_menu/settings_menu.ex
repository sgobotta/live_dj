defmodule LiveDjWeb.Components.SettingsMenu do
  @moduledoc """
  Responsible for displaying the settings
  """

  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
