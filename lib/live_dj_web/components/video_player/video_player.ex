defmodule LiveDjWeb.Components.VideoPlayer do
  @moduledoc """
  Responsible for displaying the video player
  """

  use LiveDjWeb, :live_component

  def update(assigns, conn) do
    {:ok,
      conn
      |> assign(assigns)
    }
  end
end
