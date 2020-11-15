defmodule LiveDjWeb.Components.Settings.UsernameEdit do
  @moduledoc """
  Responsible for displaying a username edit form
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Accounts

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end

  def handle_event(
    "submit_changeset",
    %{"user" => user_params, "current_password" => password},
    socket
  ) do
    %{current_user: current_user} = socket.assigns
    user = current_user

    case Accounts.apply_user_username(user, password, user_params) do
      {:ok, _user} ->
        case Accounts.update_user_username(user, password, user_params) do
          {:ok, user} ->
            %{user: %{uuid: uuid}, room: %{slug: slug}} = socket.assigns
            :ok = Phoenix.PubSub.broadcast(
              LiveDj.PubSub,
              "room:" <> slug,
              {:username_changed, %{uuid: uuid, username: user.username}}
            )
            {:noreply,
              socket
              |> put_flash(:info, "Username updated successfully.")}

          {:error, changeset} ->
            {:noreply, assign(socket, :username_changeset, changeset)}
        end
      {:error, changeset} ->
        {:noreply, assign(socket, :username_changeset, changeset)}
    end
  end
end
