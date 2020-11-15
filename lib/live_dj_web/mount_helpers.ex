defmodule LiveDjWeb.MountHelpers do
  import Phoenix.LiveView

  alias LiveDj.Accounts
  alias LiveDj.Accounts.User

  def assign_defaults(socket, _params, session) do
    socket
    |> assign_current_user(session)
    |> assign_initial_changesets()
  end

  defp assign_initial_changesets(socket) do
    %{current_user: current_user, visitor: visitor} = socket.assigns
    case visitor do
      true ->
        socket
        |> assign(:user_changeset, Accounts.change_user_registration(%User{}, current_user))
      false ->
        socket
        |> assign(:user_changeset, Accounts.change_user_username(%User{}))
    end
  end

  defp assign_current_user(socket, session) do
    user = LiveDj.Accounts.get_user_by_session_token(session["user_token"])
    %{user: user, visitor: visitor} = case user do
      nil -> %{ user: %{username: "guest#{System.unique_integer()}"}, visitor: true}
      user -> %{ user: user, visitor: false}
    end
    socket
    |> assign_new(:current_user, fn -> user end)
    |> assign_new(:visitor, fn -> visitor end)
  end
end
