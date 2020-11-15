defmodule LiveDjWeb.Components.Settings.UserRegistration do
  @moduledoc """
  Responsible for displaying the User registration form
  """

  use LiveDjWeb, :live_component

  def update(assigns, conn) do
    {:ok,
      conn
      |> assign(:trigger_submit, true)
      |> assign(assigns)
    }
  end

  def handle_event("submit_changeset", user, socket) do
    {:noreply, assign(socket, user_changeset: user)}
  end
end
