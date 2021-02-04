defmodule LiveDjWeb.Components.SectionsGroup do
  @moduledoc """
  Responsible for displaying a sections group
  """

  use LiveDjWeb, :live_component

  def update(assigns, conn) do
    {:ok,
      conn
      |> assign(assigns)
    }
  end
end
