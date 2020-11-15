defmodule LiveDjWeb.Components.Settings.UserRegistration do
  @moduledoc """
  Responsible for displaying the User registration form
  """

  use LiveDjWeb, :live_component

  def update(assigns, conn) do
    {:ok,
      conn
      |> assign(assigns)
    }
  end
end
