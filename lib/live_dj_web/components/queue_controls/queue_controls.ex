defmodule LiveDjWeb.Components.QueueControls do
  @moduledoc """
  Responsible for displaying the queue controls
  """

  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
