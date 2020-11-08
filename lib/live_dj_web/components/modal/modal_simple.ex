defmodule LiveDjWeb.Components.ModalSimple do
  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
