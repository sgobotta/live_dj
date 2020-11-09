defmodule LiveDjWeb.Components.Queue do
  @moduledoc """
  Responsible for displaying the queue
  """

  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
