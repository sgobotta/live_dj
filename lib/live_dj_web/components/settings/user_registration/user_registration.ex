defmodule LiveDjWeb.Components.Settings.UserRegistration do
  @moduledoc """
  Responsible for displaying the User registration form
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Accounts
  alias LiveDj.Accounts.User

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(:trigger_submit, false)
      |> assign(assigns)
    }
  end

  def handle_event("submit_changeset", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign(socket, user_changeset: changeset, trigger_submit: true)}
  end
end
