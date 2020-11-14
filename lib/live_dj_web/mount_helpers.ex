defmodule LiveDjWeb.MountHelpers do
  import Phoenix.LiveView

  def assign_defaults(socket, _params, session) do
    socket
    |> assign_current_user(session)
  end

  defp assign_current_user(socket, session) do
    assign_new(socket, :current_user, fn ->
      LiveDj.Accounts.get_user_by_session_token(session["user_token"])
    end)
  end
end
