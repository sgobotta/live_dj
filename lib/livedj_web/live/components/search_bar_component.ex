defmodule LivedjWeb.Components.SearchBarComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  def open_modal(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#searchbox_container",
      transition:
        {"transition ease-out duration-200", "opacity-0 scale-95",
         "opacity-100 scale-100"}
    )
    |> JS.show(
      to: "#searchbar-dialog",
      transition:
        {"transition ease-in duration-100", "opacity-0", "opacity-100"}
    )
    |> JS.focus(to: "#search-input")
  end

  def hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#searchbar-searchbox_container",
      transition:
        {"transition ease-in duration-300", "opacity-100 scale-100",
         "opacity-0 scale-95"}
    )
    |> JS.hide(
      to: "#searchbar-dialog",
      transition:
        {"transition ease-in duration-300", "opacity-100", "opacity-0"}
    )
  end
end
