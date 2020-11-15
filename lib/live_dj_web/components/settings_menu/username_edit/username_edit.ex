defmodule LiveDjWeb.Components.Settings.UsernameEdit do
  @moduledoc """
  Responsible for displaying a username edit form
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Accounts
  alias LiveDj.Accounts.User

  def update(assigns, conn) do
    {:ok,
      conn
      |> assign(assigns)
    }
  end

  def handle_event("submit_changeset", %{"user" => user_params}, conn) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->

        conn
        |> put_flash(:info, "User created successfully.")
        {:noreply, conn}

      {:error, %Ecto.Changeset{} = changeset} ->

        {:noreply,
          conn
          |> assign(:username_changeset, changeset)}
    end
  end
end
