defmodule LiveDjWeb.PoliciesController do
  use LiveDjWeb, :controller

  def index(conn, %{"policy" => "terms"})   do
    render(conn, "privacy_policy.html")
  end
end
