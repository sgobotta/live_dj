defmodule LiveDjWeb.DonationsController do
  use LiveDjWeb, :controller

  def index(conn, _params)   do
    render(conn, "index.html")
  end

  def new(conn, _params) do
    conn
      |> redirect(to: "/donations/thanks")
  end

  def thanks(conn, _params) do
    %{assigns: %{current_user: current_user, visitor: visitor}} = conn
    case visitor do
      true ->
        render(conn, "new.html", username: "Guest")
      false ->
        render(conn, "new.html", username: current_user.username)
    end
  end
end
