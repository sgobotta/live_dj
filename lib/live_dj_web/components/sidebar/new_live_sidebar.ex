defmodule LiveDjWeb.Components.NewLiveSidebar do
  @moduledoc """
  Responsible for displaying the new live sidebar
  """

  use LiveDjWeb, :live_component

  def update(assigns, conn) do
    {:ok,
      conn
      |> assign(assigns)
    }
  end
end
