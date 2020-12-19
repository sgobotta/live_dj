defmodule LiveDjWeb.DonationsController do
  use LiveDjWeb, :controller

  def index(conn, _params)   do
    render(conn, "index.html")
  end
end
