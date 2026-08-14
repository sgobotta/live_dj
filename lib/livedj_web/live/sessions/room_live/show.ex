defmodule LivedjWeb.Sessions.RoomLive.Show do
  @moduledoc false
  alias Livedj.Sessions.Room
  use LivedjWeb, {:live_view, layout: {LivedjWeb.Layouts, :session}}

  alias Livedj.Presence
  alias Livedj.Sessions
  alias Livedj.Sessions.Chat.Commands.Dispatcher, as: ChatDispatcher
  alias Livedj.Sessions.Exceptions.SessionRoomError
  alias LivedjWeb.RoomAuth

  import Phoenix.Component

  # ----------------------------------------------------------------------------
  # Chat command metadata
  #

  @doc """
  Returns the list of slash commands available in the chat, with the argument
  hint and description shown in the command preview.
  """
  @spec chat_commands() :: [
          %{name: binary(), args: binary(), description: binary()}
        ]
  def chat_commands do
    [
      %{
        name: "me",
        args: "<action>",
        description: gettext("Send an action message")
      },
      %{name: "skip", args: "", description: gettext("Skip to the next track")},
      %{
        name: "queue",
        args: "<url>",
        description: gettext("Add a track to the queue")
      },
      %{
        name: "name",
        args: "<new name>",
        description: gettext("Change your display name")
      },
      %{
        name: "msg",
        args: "<room> <message>",
        description: gettext("Send a message to another room")
      }
    ]
  end

  @doc """
  Given the current chat input, returns the commands to preview.

  Only matches while the user is still typing the command name (a leading `/`
  with no space yet). Returns `[]` when the preview should be hidden.
  """
  @spec chat_command_suggestions(binary() | nil) :: [map()]
  def chat_command_suggestions("/" <> rest) do
    if String.contains?(rest, " ") do
      []
    else
      prefix = String.downcase(rest)
      Enum.filter(chat_commands(), &String.starts_with?(&1.name, prefix))
    end
  end

  def chat_command_suggestions(_content), do: []

  @doc """
  Renders an `:announcement` message's actor name.

  Kept as its own tightly-scoped template (rather than inlined in
  show.html.heex) so `mix format` reflowing the call site can never insert
  whitespace inside the underline — that whitespace would render underlined
  too.
  """
  attr :name, :string, required: true

  def announcement_name(assigns) do
    ~H"""
    <span class="font-semibold underline">{@name}</span>
    """
  end

  @impl true
  def mount(params, session, socket) do
    %Room{id: room_id} = room = Sessions.get_room!(params["id"])

    socket =
      assign(socket,
        list_lv_id: playlist_liveview_id(),
        player_container_id: "player-container",
        spinner_id: "player-spinner",
        backdrop_id: "player-backdrop",
        start_time_tracker_id: "player-controls-start-time-tracker",
        end_time_tracker_id: "player-controls-end-time-tracker",
        time_slider_id: "player-controls-time-slider",
        form: to_form(%{}),
        chat_form: to_form(%{}),
        player: nil,
        room: room,
        room_url: nil,
        chat_visible: true,
        messages: [],
        display_name: initial_display_name(socket, room, session),
        content_ready: connected?(socket)
      )

    socket =
      if connected?(socket) do
        {:ok, :joined} = Sessions.join_player(room_id)
        {:ok, messages} = Sessions.join_chat(room_id)
        {:ok, _ref} = Presence.track_user(room_id, socket.assigns.current_user)
        :ok = Sessions.subscribe_room(room_id)

        socket
        |> assign(:messages, messages)
        |> push_event("on_container_mounted", %{
          backdrop_id: socket.assigns.backdrop_id,
          player_container_id: socket.assigns.player_container_id,
          spinner_id: socket.assigns.spinner_id,
          start_time_tracker_id: socket.assigns.start_time_tracker_id,
          end_time_tracker_id: socket.assigns.end_time_tracker_id,
          time_slider_id: socket.assigns.time_slider_id
        })
      else
        socket
      end

    {:ok, socket}
  rescue
    error in SessionRoomError ->
      case error do
        %SessionRoomError{reason: :room_not_found} ->
          {:ok,
           socket
           |> put_flash(:error, dgettext("errors", "The room doesn't exist"))
           |> redirect(to: ~p"/")}
      end

    _error ->
      {:ok,
       socket
       |> put_flash(:error, dgettext("errors", "Something went wrong!"))
       |> redirect(to: ~p"/")}
  end

  @impl true
  def handle_params(%{"id" => _id} = params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.room.name}")
    |> assign(:room_url, nil)
  end

  defp apply_action(socket, :welcome, _params) do
    room_url = url(~p"/sessions/rooms/#{socket.assigns.room}")

    socket
    |> assign(:page_title, "#{socket.assigns.room.name}")
    |> assign(:room_url, room_url)
  end

  defp apply_action(socket, :browse, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.room.name}")
  end

  defp apply_action(socket, :help, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.room.name}")
  end

  defp apply_action(socket, :settings, _params) do
    assign(socket, :page_title, "#{socket.assigns.room.name}")
  end

  # ----------------------------------------------------------------------------
  # Client side event handling
  #

  def handle_event("update_chat_input", %{"content" => content}, socket) do
    {:noreply, assign(socket, :chat_form, to_form(%{"content" => content}))}
  end

  def handle_event("select_chat_command", %{"name" => name}, socket) do
    {:noreply,
     socket
     |> assign(:chat_form, to_form(%{"content" => "/#{name} "}))
     |> push_event("focus_chat_input", %{})}
  end

  def handle_event("toggle_chat", _params, socket) do
    {:noreply, update(socket, :chat_visible, &(!&1))}
  end

  def handle_event("open_and_focus_chat", _params, socket) do
    socket =
      if socket.assigns.chat_visible,
        do: socket,
        else: assign(socket, :chat_visible, true)

    {:noreply, push_event(socket, "focus_chat_input", %{})}
  end

  def handle_event("send_chat_message", %{"content" => content}, socket) do
    if String.trim(content) == "" do
      {:noreply, socket}
    else
      user_id = to_string(socket.assigns.current_user.id)

      socket =
        case ChatDispatcher.dispatch(
               socket.assigns.room.id,
               user_id,
               socket.assigns.display_name,
               content
             ) do
          :ok ->
            socket

          {:local, message} ->
            update(socket, :messages, &Enum.take([message | &1], 200))

          {:display_name_changed, new_name} ->
            socket
            |> assign(:display_name, new_name)
            |> push_event("store_display_name", %{name: new_name})
        end

      {:noreply, assign(socket, :chat_form, to_form(%{"content" => ""}))}
    end
  end

  def handle_event("open_share_modal", _params, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/sessions/rooms/#{socket.assigns.room}/welcome")}
  end

  def handle_event("open_help_modal", _params, socket) do
    if socket.assigns.live_action == :help do
      {:noreply,
       push_patch(socket, to: ~p"/sessions/rooms/#{socket.assigns.room}")}
    else
      {:noreply,
       push_patch(socket, to: ~p"/sessions/rooms/#{socket.assigns.room}/help")}
    end
  end

  def handle_event("open_settings_modal", _params, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/sessions/rooms/#{socket.assigns.room}/settings")}
  end

  def handle_event("save_room_password", %{"password" => password}, socket) do
    save_password(socket, %{"password" => password})
  end

  def handle_event("remove_room_password", _params, socket) do
    save_password(socket, %{"password" => ""})
  end

  def handle_event("on_player_play", _params, socket) do
    # On click event callback
    :ok = Sessions.play(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("on_player_pause", %{"current_time" => current_time}, socket) do
    # On click event callback
    :ok = Sessions.pause(socket.assigns.room.id, at: current_time)
    {:noreply, socket}
  end

  def handle_event("on_player_playing", _params, socket) do
    # The player state changed to playing.
    {:noreply, socket}
  end

  def handle_event("on_player_paused", _params, socket) do
    # The player state changed to paused.
    {:noreply, socket}
  end

  def handle_event("on_player_ended", _params, socket) do
    :ok = Sessions.report_track_ended(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("on_player_loaded", _params, socket) do
    socket =
      if connected?(socket) and is_nil(socket.assigns.player) do
        {:ok, %Sessions.Player{} = player} =
          Sessions.get_player(socket.assigns.room.id)

        socket
        |> assign_player(player)
        |> push_event("show_player", %{callback_event: "on_player_visible"})
        |> push_event("load_video", player)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("on_player_visible", _params, socket) do
    {:noreply, socket}
  end

  @out_of_sync_threshold_seconds 5

  def handle_event(
        "seek_committed",
        %{"committed_time" => committed_time},
        socket
      ) do
    room_id = socket.assigns.room.id

    case Sessions.get_player(room_id) do
      {:ok, %Sessions.Player{state: state, current_time: room_time}}
      when state in [:playing, :paused] ->
        delta = abs(trunc(room_time) - trunc(committed_time))

        if delta > @out_of_sync_threshold_seconds do
          message =
            if committed_time > room_time do
              gettext("You're %{delta}s ahead of the room.", delta: delta)
            else
              gettext("You're %{delta}s behind the room.", delta: delta)
            end

          {:noreply,
           push_event(socket, "player_out_of_sync", %{message: message})}
        else
          {:noreply, socket}
        end

      _other ->
        {:noreply, socket}
    end
  end

  def handle_event("on_player_resync", _params, socket) do
    case Sessions.get_player(socket.assigns.room.id) do
      {:ok, %Sessions.Player{current_time: room_time}} ->
        {:noreply,
         push_event(socket, "set_current_time", %{current_time: room_time})}

      _error ->
        {:noreply, socket}
    end
  end

  defp save_password(socket, attrs) do
    case Sessions.update_room_password(socket.assigns.room, attrs) do
      {:ok, room} ->
        {:noreply,
         socket
         |> assign(:room, room)
         |> put_flash(:info, gettext("Room password updated"))
         |> push_patch(to: ~p"/sessions/rooms/#{room}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, password_error_message(changeset))}
    end
  end

  defp password_error_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn error ->
      LivedjWeb.CoreComponents.translate_error(error)
    end)
    |> Map.get(:password, [])
    |> Enum.join(", ")
    |> case do
      "" -> gettext("Invalid password")
      message -> message
    end
  end

  # ----------------------------------------------------------------------------
  # Server side Playlist event handling
  #

  @impl true
  def handle_info(
        {:playlist_joined, room_id, _payload},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_info({:track_added, _room_id, media}, socket) do
    send_update(LivedjWeb.Components.SearchBarComponent,
      id: "browse-search-bar",
      track_added: media
    )

    {:noreply, socket}
  end

  def handle_info({:track_removed, _room_id, external_id}, socket) do
    send_update(LivedjWeb.Components.SearchBarComponent,
      id: "browse-search-bar",
      track_removed: external_id
    )

    {:noreply, socket}
  end

  def handle_info({:track_moved, _room_id, _payload}, socket),
    do: {:noreply, socket}

  def handle_info(:dragging_locked, socket), do: {:noreply, socket}

  def handle_info(:dragging_unlocked, socket), do: {:noreply, socket}

  def handle_info({:dragging_cancelled, _room_id}, socket),
    do: {:noreply, socket}

  # ----------------------------------------------------------------------------
  # Server side Player event handling
  #

  def handle_info(
        {:player_joined, _room_id, %{player: %Sessions.Player{}}},
        socket
      ) do
    {:noreply, socket}
  end

  def handle_info(
        {:player_state_changed, room_id, %Sessions.Player{}},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_info(
        {:player_play, _room_id, %Sessions.Player{}},
        socket
      ) do
    # Broadcasted request to send a play signal to the player
    {:noreply,
     push_event(socket, "play_video", %{
       callback_event: "on_player_playing"
     })}
  end

  def handle_info({:player_pause, _room_id, %Sessions.Player{}}, socket) do
    # Broadcasted request to send a pause signal to the player
    {:noreply,
     push_event(socket, "pause_video", %{callback_event: "on_player_paused"})}
  end

  def handle_info(
        {:player_load_media, _room_id, %Sessions.Player{} = player},
        socket
      ) do
    {:noreply,
     socket
     |> assign_player(player)
     |> push_event("load_video", player)}
  end

  def handle_info({:track_ended, _room_id}, socket), do: {:noreply, socket}

  # ----------------------------------------------------------------------------
  # Server side Chat event handling
  #

  def handle_info({:message_sent, _room_id, message}, socket) do
    {:noreply, update(socket, :messages, &Enum.take([message | &1], 200))}
  end

  def handle_info({:messages_updated, _room_id, messages}, socket) do
    {:noreply, assign(socket, :messages, messages)}
  end

  # Already applied locally (see the `{:display_name_changed, new_name}` case
  # in handle_event("send_chat_message", ...)); the message list refresh from
  # `:messages_updated` is what keeps rendered messages in sync.
  def handle_info(
        {:display_name_changed, _room_id, _user_id, _new_name},
        socket
      ) do
    {:noreply, socket}
  end

  # A password change re-keys the room's authorization fingerprint, which would
  # re-lock everyone currently in the room on their next reload. Refresh the
  # in-memory room (so the header/badge update live) and, for a still-protected
  # room, hand the client a fresh short-lived grant so it can silently rewrite
  # its authorization cookie with the new fingerprint and keep access.
  def handle_info(
        {:password_changed, room_id},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    room = Sessions.get_room!(room_id)
    socket = assign(socket, :room, room)

    socket =
      if Sessions.room_protected?(room) do
        push_event(socket, "refresh_room_grant", %{
          url:
            ~p"/sessions/rooms/#{room}/unlock/grant?#{[token: RoomAuth.sign_grant(room.id), silent: true]}"
        })
      else
        socket
      end

    {:noreply, socket}
  end

  @spec assign_player(Phoenix.LiveView.Socket.t(), Sessions.Player.t()) ::
          Phoenix.LiveView.Socket.t()
  defp assign_player(socket, player), do: assign(socket, :player, player)

  # Prefer the name the client persisted for this room (delivered from a cookie
  # via the session, so it is available during the disconnected HTTP render and
  # avoids a flash of the default name), falling back to the account username.
  defp initial_display_name(socket, room, session) do
    stored_display_name(session, room) || account_display_name(socket)
  end

  defp stored_display_name(session, room) do
    with %{"display_names" => %{} = names} <- session,
         name when is_binary(name) and name != "" <-
           Map.get(names, to_string(room.id)) do
      name
    else
      _no_stored_name -> nil
    end
  end

  defp account_display_name(socket) do
    user = socket.assigns.current_user
    user.username || to_string(user.id)
  end

  defp playlist_liveview_id, do: "playlist-lv-#{Ecto.UUID.generate()}"
end
