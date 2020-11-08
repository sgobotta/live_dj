defmodule LiveDjWeb.Components.Chat do
  @moduledoc """
  Responsible for chat interactions
  """

  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
