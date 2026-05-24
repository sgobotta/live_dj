defmodule LivedjWeb.SessionModals do
  @moduledoc false

  use LivedjWeb, :html

  attr :room, :map, required: true
  attr :room_url, :string, default: nil
  attr :show, :boolean, required: true

  def welcome_modal(assigns) do
    ~H"""
    <.modal
      :if={@show}
      id="welcome-modal"
      show
      on_cancel={JS.patch(~p"/sessions/rooms/#{@room}")}
    >
      <.header>
        {gettext("Room ready to share!")}
        <:subtitle>
          {gettext("Share the link below with your friends so they can join")}
        </:subtitle>
      </.header>

      <div class="mt-6 flex flex-col gap-3">
        <p class="text-2xl font-semibold text-zinc-900 dark:text-zinc-100 text-center">
          {@room.name}
        </p>
        <div class="flex items-center gap-2 rounded-lg bg-zinc-100 dark:bg-zinc-800 px-4 py-3">
          <span class="flex-1 truncate text-sm text-zinc-700 dark:text-zinc-300 font-mono select-all">
            {@room_url}
          </span>
          <button
            phx-hook="Clipboard"
            id="copy-room-url"
            data-copy-text={@room_url}
            class="
              shrink-0 rounded-md px-3 py-1.5 text-xs font-semibold
              bg-zinc-900 dark:bg-zinc-100
              text-zinc-50 dark:text-zinc-900
              hover:bg-zinc-700 dark:hover:bg-zinc-300
              transition-colors duration-150
            "
          >
            {gettext("Copy")}
          </button>
        </div>
      </div>

      <div class="mt-6 flex justify-end">
        <.link patch={~p"/sessions/rooms/#{@room}"}>
          <.button>
            {gettext("Enter room")}
          </.button>
        </.link>
      </div>
    </.modal>
    """
  end

  attr :room, :map, required: true
  attr :show, :boolean, required: true

  def browse_modal(assigns) do
    ~H"""
    <.modal
      :if={@show}
      id="browse-modal"
      show
      on_cancel={JS.patch(~p"/sessions/rooms/#{@room}")}
    >
      <.live_component
        id="browse-search-bar"
        module={LivedjWeb.Components.SearchBarComponent}
        room={@room}
        close_patch={~p"/sessions/rooms/#{@room}"}
      />
    </.modal>
    """
  end
end
