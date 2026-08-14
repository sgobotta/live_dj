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
    </.modal>
    """
  end

  attr :room, :map, required: true
  attr :show, :boolean, required: true
  attr :user_id, :string, required: true
  attr :display_name, :string, required: true

  def browse_modal(assigns) do
    ~H"""
    <div
      :if={@show}
      id="browse-modal"
      phx-mounted={show_browse_sheet("browse-modal")}
      phx-remove={hide_browse_sheet("browse-modal")}
      data-cancel={JS.exec(JS.patch(~p"/sessions/rooms/#{@room}"), "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id="browse-modal-bg"
        class="fixed inset-0 bg-zinc-100/90 dark:bg-zinc-900/90 transition-opacity"
        aria-hidden="true"
      />
      <div class="fixed inset-0 flex items-end sm:items-center sm:justify-center">
        <div
          id="browse-modal-panel"
          phx-window-keydown={JS.exec("data-cancel", to: "#browse-modal")}
          phx-key="escape"
          phx-click-away={JS.exec("data-cancel", to: "#browse-modal")}
          class="
            relative w-full sm:max-w-lg
            rounded-t-2xl sm:rounded-2xl
            bg-zinc-200 dark:bg-zinc-900
            border border-zinc-500 dark:border-zinc-500
            shadow-lg
          "
        >
          <%!-- Drag handle (mobile only) --%>
          <div class="flex justify-center pt-3 pb-1 sm:hidden" aria-hidden="true">
            <div class="h-1 w-10 rounded-full bg-zinc-400 dark:bg-zinc-600" />
          </div>
          <%!-- Close button (desktop only) --%>
          <div id="browse-modal-content" class="p-4 pt-4 pb-8 sm:pb-4">
            <.live_component
              id="browse-search-bar"
              module={LivedjWeb.Components.SearchBarComponent}
              room={@room}
              user_id={@user_id}
              display_name={@display_name}
              close_patch={~p"/sessions/rooms/#{@room}"}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :room, :map, required: true
  attr :show, :boolean, required: true

  def help_modal(assigns) do
    ~H"""
    <.modal
      :if={@show}
      id="help-modal"
      show
      on_cancel={JS.patch(~p"/sessions/rooms/#{@room}")}
    >
      <div phx-window-keydown="open_help_modal" phx-key="h" class="hidden" />
      <div phx-window-keydown="open_help_modal" phx-key="?" class="hidden" />
      <.header>
        {gettext("Keyboard Shortcuts")}
        <:subtitle>
          {gettext("Press any key below while in the session")}
        </:subtitle>
      </.header>

      <div class="mt-6">
        <dl class="divide-y divide-zinc-400 dark:divide-zinc-700">
          <.help_row key="S" label={gettext("Share room URL")} />
          <.help_row key="A" label={gettext("Search and add tracks")} />
          <.help_row key="C" label={gettext("Toggle chat")} />
          <.help_row key="Y" label={gettext("Focus chat")} />
          <.help_row key="T" label={gettext("Toggle theme")} />
          <.help_row key="M" label={gettext("Mute / Unmute player")} />
          <.help_row key={gettext("Space")} label={gettext("Play / Pause")} />
          <.help_row key="F" label={gettext("Toggle fullscreen")} />
          <.help_row key={gettext("H or ?")} label={gettext("Show this help")} />
        </dl>
      </div>
    </.modal>
    """
  end

  attr :key, :string, required: true
  attr :label, :string, required: true

  defp help_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between py-3">
      <dt class="text-sm text-zinc-600 dark:text-zinc-400">{@label}</dt>
      <dd>
        <kbd class="
          inline-flex items-center rounded border border-zinc-400 dark:border-zinc-600
          px-2 py-0.5 text-xs font-mono font-semibold
          bg-zinc-100 dark:bg-zinc-800
          text-zinc-700 dark:text-zinc-300
        ">
          {@key}
        </kbd>
      </dd>
    </div>
    """
  end

  attr :room, :map, required: true
  attr :show, :boolean, required: true

  def password_modal(assigns) do
    assigns =
      assign(assigns, :protected, not is_nil(assigns.room.password_hash))

    ~H"""
    <.modal
      :if={@show}
      id="room-password-modal"
      show
      on_cancel={JS.patch(~p"/sessions/rooms/#{@room}")}
    >
      <.header>
        {gettext("Room password")}
        <:subtitle>
          <%= if @protected do %>
            {gettext("This room is protected. Update or remove its password.")}
          <% else %>
            {gettext("Add a password to protect this room.")}
          <% end %>
        </:subtitle>
      </.header>

      <.form
        for={%{}}
        id="room-password-form"
        phx-submit="save_room_password"
        class="mt-6 flex flex-col gap-4"
      >
        <input
          type="password"
          name="password"
          placeholder={gettext("New password")}
          class="w-full rounded-lg border border-tone-300 dark:border-tone-600 bg-transparent px-3 py-2 text-tone-900 dark:text-tone-100 focus:ring-2 focus:ring-tone-900 focus:dark:ring-tone-50"
        />
        <div class="flex items-center justify-between gap-2">
          <button
            :if={@protected}
            type="button"
            id="remove-room-password"
            phx-click="remove_room_password"
            class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline"
          >
            {gettext("Remove password")}
          </button>
          <.button phx-disable-with={gettext("Saving...")} class="ml-auto">
            {gettext("Save")}
          </.button>
        </div>
      </.form>
    </.modal>
    """
  end

  defp show_browse_sheet(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition:
        {"transition-opacity ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-panel",
      transition: {
        "transition-all transform ease-out duration-300",
        "translate-y-full sm:translate-y-0 sm:opacity-0 sm:scale-95",
        "translate-y-0 sm:opacity-100 sm:scale-100"
      }
    )
    |> JS.focus_first(to: "##{id}-content")
  end

  defp hide_browse_sheet(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition:
        {"transition-opacity ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-panel",
      time: 200,
      transition: {
        "transition-all transform ease-in duration-200",
        "translate-y-0 sm:opacity-100 sm:scale-100",
        "translate-y-full sm:opacity-0 sm:scale-95"
      }
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.pop_focus()
  end
end
