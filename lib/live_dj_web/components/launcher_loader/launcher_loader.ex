defmodule LiveDjWeb.Components.LauncherLoader do
  @moduledoc """
  Responsible for displaying a loader at launch time
  """

  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
