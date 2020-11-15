defmodule LiveDjWeb.Components.Settings do
  @moduledoc """
  Responsible for displaying the settings
  """

  use LiveDjWeb, :live_component

  def update(assigns, conn) do
    {:ok,
      conn
      |> assign(assigns)
    }
  end
end
