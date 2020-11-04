defmodule LiveDjWeb.Components.ModalSimple do
  use LiveDjWeb, :live_component

  alias LiveDjWeb.Components.Modal

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
