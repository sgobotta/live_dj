defmodule LiveDjWeb.Components.Header do
  @moduledoc """
  Responsible for displaying a header
  """

  use LiveDjWeb, :live_component

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(:user_changeset, %{})
      |> assign(assigns)
    }
  end
end
