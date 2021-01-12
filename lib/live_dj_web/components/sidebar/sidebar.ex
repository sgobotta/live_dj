defmodule LiveDjWeb.Components.Sidebar do
  @moduledoc """
  Responsible for displaying the sidebar
  """

  use LiveDjWeb, :live_component

  def update(assigns, conn) do
    {:ok,
      conn
      |> assign(assigns)
    }
  end
end
