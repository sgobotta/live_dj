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
        <div class="flex items-center gap-2">
          <.input
            container_class="flex-1"
            type="text"
            id="room-url-input"
            name="room_url"
            value={@room_url}
            readonly
            aria-label={gettext("Room URL")}
            class="mt-0! truncate font-mono text-sm"
          />
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
              focus:outline-none focus-ignite
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
            bg-tone-200 dark:bg-tone-950
            border border-tone-500 dark:border-tone-600
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
          <.help_row key=";" label={gettext("Open settings")} />
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
          inline-flex items-center rounded border border-brand/30 dark:border-brand/40
          px-2 py-0.5 text-xs font-mono font-semibold
          bg-brand/5 dark:bg-brand/20
          text-brand dark:text-brand
        ">
          {@key}
        </kbd>
      </dd>
    </div>
    """
  end

  attr :room, :map, required: true
  attr :show, :boolean, required: true
  attr :tab, :atom, required: true, values: [:general, :security]
  attr :current_user, :any, required: true
  attr :display_name, :string, required: true

  def settings_modal(assigns) do
    assigns =
      assign(assigns, :protected, not is_nil(assigns.room.password_hash))

    ~H"""
    <.modal
      :if={@show}
      id="room-settings-modal"
      show
      on_cancel={JS.patch(~p"/sessions/rooms/#{@room}")}
      content_class="px-5 pb-5 pt-3"
      close_button_class="top-3 right-8"
    >
      <div
        id="settings-modal-tabs"
        phx-hook="TabIndicator"
        class="relative inline-flex gap-1"
      >
        <.modal_tab
          patch={~p"/sessions/rooms/#{@room}/settings/general"}
          active={@tab == :general}
        >
          <.icon name="hero-cog-6-tooth" class="h-4 w-4" /> {gettext("General")}
        </.modal_tab>
        <.modal_tab
          patch={~p"/sessions/rooms/#{@room}/settings/security"}
          active={@tab == :security}
        >
          <.icon
            name={if @protected, do: "hero-lock-closed", else: "hero-lock-open"}
            class="h-4 w-4"
          /> {gettext("Security")}
        </.modal_tab>
        <span
          class="absolute bottom-0 h-0.5 bg-tone-900 dark:bg-tone-100 transition-all duration-200 ease-out"
          style="left: 0; width: 0;"
        />
      </div>

      <div class="mt-6 h-96 overflow-y-auto overflow-x-hidden pr-2">
        <div
          :if={@tab == :general}
          phx-mounted={
            JS.transition(
              {"transition-all ease-out duration-200", "opacity-0 translate-y-1",
               "opacity-100 translate-y-0"}
            )
          }
        >
          <.form
            for={%{}}
            id="general-settings-form"
            phx-submit="save_general"
            class="flex flex-col gap-6"
          >
            <div class="flex items-center gap-4">
              <.user_avatar
                id="settings-user-avatar"
                user={@current_user}
                name={@display_name}
                class="h-14 w-14 text-lg"
                tooltip={false}
              />
              <.input
                container_class="flex-1 flex flex-col gap-2"
                type="text"
                id="display-name-input"
                name="display_name"
                value={@display_name}
                label={gettext("Your name")}
                placeholder={gettext("Your name")}
              />
            </div>

            <div class="border-t border-tone-300 dark:border-tone-600 pt-6">
              <.input
                type="text"
                id="room-name-input"
                name="name"
                value={@room.name}
                label={gettext("Room name")}
                placeholder={gettext("Room name")}
              />
            </div>

            <.button phx-disable-with={gettext("Saving...")} class="ml-auto">
              {gettext("Save")}
            </.button>
          </.form>

          <div class="border-t border-tone-300 dark:border-tone-600 pt-6 mt-6">
            <.toggle_switch
              id="track-notifications-toggle"
              hook="NotificationsToggle"
              label={gettext("Track notifications")}
              description={
                gettext(
                  "Show a browser notification when the playing track changes"
                )
              }
            />
          </div>
        </div>

        <div
          :if={@tab == :security}
          phx-mounted={
            JS.transition(
              {"transition-all ease-out duration-200", "opacity-0 translate-y-1",
               "opacity-100 translate-y-0"}
            )
          }
        >
          <p class="text-sm text-zinc-600 dark:text-zinc-400">
            <%= if @protected do %>
              {gettext("This room is protected. Update or remove its password.")}
            <% else %>
              {gettext("Add a password to protect this room.")}
            <% end %>
          </p>

          <.form
            for={%{}}
            id="room-password-form"
            phx-submit="save_room_password"
            class="mt-4 flex flex-col gap-4"
          >
            <.input
              type="password"
              name="password"
              value=""
              placeholder={gettext("New password")}
            />
            <div class="flex items-center justify-between gap-2">
              <button
                :if={@protected}
                type="button"
                id="remove-room-password"
                phx-click="remove_room_password"
                class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline focus:outline-none focus-ignite rounded"
              >
                {gettext("Remove password")}
              </button>
              <.button phx-disable-with={gettext("Saving...")} class="ml-auto">
                {gettext("Save")}
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </.modal>
    """
  end

  # Scoped to settings_modal for now. If a second tabbed modal shows up,
  # extract this into a generic tabbed_modal/modal_tab pair instead of
  # copying it.
  attr :patch, :string, required: true
  attr :active, :boolean, required: true
  slot :inner_block, required: true

  defp modal_tab(assigns) do
    ~H"""
    <.link
      patch={@patch}
      data-active={to_string(@active)}
      class={[
        "flex items-center gap-1.5 px-3 py-2 text-sm font-semibold transition-colors",
        "rounded-t focus:outline-none focus-ignite",
        @active && "text-tone-900 dark:text-tone-100",
        !@active &&
          "text-tone-500 dark:text-tone-400 hover:text-tone-700 dark:hover:text-tone-300"
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
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
