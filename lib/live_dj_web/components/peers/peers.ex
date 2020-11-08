defmodule LiveDjWeb.Components.Peers do
  @moduledoc """
  Responsible for displaying information about other peers
  """

  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
