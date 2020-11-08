defmodule LiveDjWeb.Components.PlayerControls do
  @moduledoc """
  Responsible for displaying the player controls
  """

  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
