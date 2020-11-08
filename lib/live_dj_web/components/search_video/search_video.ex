defmodule LiveDjWeb.Components.SearchVideo do
  @moduledoc """
  Responsible for displaying video search results
  """

  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end
end
