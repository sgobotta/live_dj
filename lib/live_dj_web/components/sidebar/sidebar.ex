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

  def handle_event("redirect_settings", _, socket) do
    {:noreply,
      socket
      |> redirect(to: Routes.user_settings_path(socket, :index))}
  end

  def handle_event("redirect_home", _, socket) do
    {:noreply,
      socket
      |> redirect(to: Routes.new_path(socket, :new))}
  end
end
