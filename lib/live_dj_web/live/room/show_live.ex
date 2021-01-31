defmodule LiveDjWeb.Room.ShowLive do
  @moduledoc """
  A LiveView for creating and joining rooms.
  """

  use LiveDjWeb, :live_view

  alias LiveDj.Accounts
  alias LiveDj.ConnectedUser
  alias LiveDj.Notifications
  alias LiveDj.Organizer
  alias LiveDj.Organizer.{Chat, Player, Queue, Video, VolumeControls}
  alias LiveDj.Payments
  alias LiveDj.ConnectedUser
  alias LiveDjWeb.Presence
  alias Phoenix.Socket.Broadcast

  # FIXME: Use this from a Controller
  alias LiveDj.Repo

  @impl true
  def mount(%{"slug" => slug} = params, session, socket) do
    room = Organizer.get_room(slug)

    case room do
      nil ->
        {:ok,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: Routes.new_path(socket, :new))
        }
      room ->
        socket = assign_defaults(socket, params, session)
        %{current_user: current_user, visitor: visitor} = socket.assigns
        user = ConnectedUser.create_connected_user(current_user.username)

        # FIXME: refactor to a group management module
        user_room_group = case visitor do
          true -> %{
            codename: "anonymous-user",
            name: "Anonymous user",
            permissions: []
          }
          false ->
            case Organizer.get_user_room_by(%{
              user_id: current_user.id,
              room_id: room.id
            }) do
              nil -> %{
                codename: "registered-user",
                name: "Registered  user",
                permissions: []
              }
              user_room ->
                user_room = Repo.preload(user_room, [:group])
                user_room.group |> Repo.preload(:permissions)
            end
        end

        room_changeset = Ecto.Changeset.change(room)

        Phoenix.PubSub.subscribe(LiveDj.PubSub, "room:" <> slug)

        # Refactor to a module that manages Presence (initial data, updates, etc.)
        volume_data = VolumeControls.get_initial_state()
        presence_meta_user_id = case visitor do
          true -> 0
          false -> current_user.id
        end
        presence_meta = Map.merge(
          volume_data,
          %{
            typing: false,
            username: user.username,
            visitor: visitor,
            group: %{
              codename: user_room_group.codename,
              name: user_room_group.name,
              permissions: user_room_group.permissions,
            },
            user_id: presence_meta_user_id
          }
        )
        {:ok, _} = Presence.track(self(), "room:" <> slug, user.uuid, presence_meta)

        parsed_queue = room.queue
        |> Enum.map(fn track -> Video.from_jsonb(track) end)

        player = Player.get_initial_state()
        {:ok,
          socket
          |> assign(:user, user)
          |> assign(:slug, slug)
          |> assign(:connected_users, [])
          |> assign(:new_message, "")
          |> assign(:messages, [])
          |> assign(:video_queue, Enum.with_index(parsed_queue))
          |> assign(:video_queue_controls, Queue.get_initial_controls())
          |> assign(:room_changeset, room_changeset)
          |> assign(:search_result, [])
          |> assign(:player, player)
          |> assign(:player_controls, Player.get_controls_state(player))
          |> assign(:volume_controls, volume_data)
          |> assign(:username_input, user.username)
          |> assign(:current_tab, "video_queue")
          |> assign(:sections_group_tab, "chat")
          |> assign(:user_room_group, user_room_group)
          |> assign_tracker(room)
        }
    end
  end

  @impl true
  def handle_info(
    %Broadcast{event: "presence_diff", payload: payload},
    %{assigns: %{slug: slug, user: user}} = socket
  ) do

    connected_users = Organizer.list_present_with_metas(slug)
    |> Enum.map(fn u ->
      %{username: username} = hd(u.metas)
      has_orders = case Accounts.get_user_by_username(username) do
        nil -> false
        user -> Payments.has_order_by_user_id(user.id)
      end
      Map.merge(u, %{metas: [Map.merge(hd(u.metas), %{is_donor: has_orders})]})
    end)

    room = handle_video_tracker_activity(slug, connected_users, payload)

    socket = socket
    |> assign(:connected_users, connected_users)
    |> assign(:room, room)

    # TODO: refactor, there should be a way to receive the diff event only when
    # others joined
    case Organizer.is_my_presence(user, payload) do
      false ->
        # %{joins: joins, leaves: leaves} = payload
        # joins = Map.to_list(joins)
        #   |> Enum.map(fn {uuid, _} -> Chat.create_message(:presence_joins, %{uuid: uuid}) end)
        # leaves = Map.to_list(leaves)
        #   |> Enum.map(fn {uuid, _} -> Chat.create_message(:presence_leaves, %{uuid: uuid}) end)

        {:noreply,
          socket
          # |> assign(:messages, messages ++ joins ++ leaves)
          |> push_event("presence-changed", %{})
        }
      true ->
        {:noreply, socket}
    end
  end

  def handle_info({:request_current_player, _params}, socket) do
    %{assigns: %{player: player, slug: slug, video_queue: video_queue}} = socket

    :ok = Phoenix.PubSub.broadcast_from(
      LiveDj.PubSub,
      self(),
      "room:" <> slug <> ":request_current_player",
      {:receive_current_player, %{
        slug: slug, player: player, video_queue: video_queue}}
    )

    {:noreply, socket}
  end

  def handle_info(
    {:add_to_queue, %{added_video_position: added_video_position, updated_video_queue: updated_video_queue, video_queue_controls: video_queue_controls}},
    %{assigns: %{player: player, search_result: search_result}} = socket
  ) do
    search_result = Enum.map(search_result, fn video ->
      Video.update(video, %{is_queued: Queue.is_queued(video, updated_video_queue)}) end)
    socket = socket
      |> assign(:search_result, search_result)
      |> assign(:video_queue, Enum.with_index(updated_video_queue))
      |> assign(:video_queue_controls, video_queue_controls)
      |> push_event("video_added_to_queue", %{pos: added_video_position})

    case updated_video_queue do
      [{v, _}] ->
        selected_video = v
        props = %{time: 0, video_id: selected_video.video_id, state: "playing", previous_id: "", next_id: ""}
        player = Player.update(player, props)
        {:noreply,
          socket
          |> assign(:player, player)
          |> assign(:player_controls, Player.get_controls_state(player))
          |> push_event("receive_player_state", Player.create_response(player))
        }
      [_v|_vs] ->
        case player.state do
          "stopped" ->
            %{video_id: video_id} = player
            next_video = Queue.get_next_video(updated_video_queue, video_id)
            %{video_id: video_id} = next_video
            player = Player.update(player, %{state: "playing", time: 0, video_id: video_id})
            {:noreply,
              socket
              |> assign(:player, player)
              |> assign(:player_controls, Player.get_controls_state(player))
              |> push_event("receive_player_state", Player.create_response(player))}
          _ ->
            {:noreply, socket}
        end
    end
  end

  def handle_info({:save_queue, params}, socket) do
    %{video_queue_controls: video_queue_controls} = params
    {:noreply,
      socket
      |> assign(:video_queue_controls, video_queue_controls)
      |> push_event("queue_saved", %{})}
  end

  def handle_info({:request_initial_state, _params}, socket) do
    %{messages: messages, video_queue: video_queue, player: player} = socket.assigns
    :ok = Phoenix.PubSub.broadcast_from(
      LiveDj.PubSub,
      self(),
      "room:" <> socket.assigns.slug <> ":request_initial_state",
      {:receive_initial_state, %{current_queue: video_queue, messages: messages, player: player}}
    )
    {:noreply, socket}
  end

  def handle_info({:receive_initial_state, params}, socket) do
    %{search_result: search_result, slug: slug} = socket.assigns
    Organizer.unsubscribe(:request_initial_state, slug)
    %{current_queue: current_queue, messages: messages, player: player} = params
    current_queue = Enum.map(current_queue, fn {v, _} -> v end)
    search_result = Enum.map(search_result, fn video ->
      Video.update(video, %{is_queued: Queue.is_queued(video, current_queue)}) end)
    socket = socket
      |> assign(:messages, messages)
      |> assign(:video_queue, Enum.with_index(current_queue))
      |> assign(:player, player)
      |> assign(:player_controls, Player.get_controls_state(player))
      |> assign(:search_result, search_result)
    case current_queue do
      []  -> {:noreply, socket}
      _xs ->
        {:noreply,
          socket
          |> push_event("receive_player_state", Player.create_response(player))}
    end
  end

  def handle_info({:player_signal_playing, %{state: state}}, socket) do
    %{player: player} = socket.assigns
    player = Player.update(player, %{state: state})
    {:noreply,
      socket
      |> assign(:player, player)
      |> assign(:player_controls, Player.get_controls_state(player))
      |> push_event("receive_playing_signal", %{})}
  end

  def handle_info({:player_signal_paused, %{state: state}}, socket) do
    %{player: player} = socket.assigns
    player = Player.update(player, %{state: state})
    {:noreply,
    socket
      |> assign(:player, player)
      |> assign(:player_controls, Player.get_controls_state(player))
      |> push_event("receive_paused_signal", %{})}
  end

# ===========================================================================
#
# Similar functions, refactor if not used to perform specific tasks
#

  def handle_info({:player_signal_play_next, %{player: player, player_controls: player_controls}}, socket) do
    {:noreply, socket
      |> assign(:player, player)
      |> assign(:player_controls, player_controls)
      |> push_event("receive_player_state", Player.create_response(player))}
  end

  def handle_info({:player_signal_play_previous, %{player: player, player_controls: player_controls}}, socket) do
    {:noreply, socket
      |> assign(:player, player)
      |> assign(:player_controls, player_controls)
      |> push_event("receive_player_state", Player.create_response(player))}
  end

#
# ===========================================================================

  def handle_info({:player_signal_play_by_id, %{video_id: video_id}}, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    selected_video = Queue.get_video_by_id(video_queue, video_id)

    case selected_video do
      nil -> {:noreply, socket}
      video ->
        params = %{
          next_id: video.next,
          previous_id: video.previous,
          time: 0,
          video_id: video.video_id,
        }
        player = Player.update(player, params)
        player_controls = Player.get_controls_state(player)
        {:noreply,
          socket
          |> assign(:player, player)
          |> assign(:player_controls, player_controls)
          |> push_event("receive_player_state", Player.create_response(player))}
    end
  end

  def handle_info({:volume_level_changed, params}, socket) do
    %{uuid: uuid, volume_level: volume_level, volume_icon: volume_icon} = params
    %{slug: slug} = socket.assigns

    Presence.update(self(), "room:" <> slug, uuid, fn m ->
      Map.merge(m, %{volume_level: volume_level, volume_icon: volume_icon})
    end)

    {:noreply, socket}
  end

  def handle_info({:user_room_group_changed, params}, socket) do
    %{group: group, topic: topic, user_id: user_id, uuid: uuid} = params

    Presence.update(self(), topic, uuid, fn m ->
      Map.merge(m, %{group: group})
    end)

    socket = case socket.assigns.visitor do
      true -> socket
      false ->
        case user_id == socket.assigns.current_user.id do
          false -> socket
          true -> assign(socket, :user_room_group, group)
        end
    end

    {:noreply, socket}
  end

  def handle_info({:remove_track, %{video_id: video_id}}, socket) do
    %{
      search_result: search_data,
      video_queue: video_queue,
      video_queue_controls: video_queue_controls
    } = socket.assigns

    video_queue = video_queue
    |> Enum.map(fn {v, _} -> v end)
    |> Queue.remove_video_by_id(video_id)

    {:noreply,
      socket
      |> assign(:search_result, Enum.map(search_data, fn video ->
        Video.update(video, %{is_queued: Queue.is_queued(video, video_queue)}) end))
      |> assign(:video_queue_controls, Queue.mark_as_unsaved(video_queue_controls))
      |> assign(:video_queue, Enum.with_index(video_queue))}
  end

  def handle_info({:player_signal_sort_video, params}, socket) do
    %{
      sorted_video_position: sorted_video_position,
      player: player,
      player_controls: player_controls,
      video_queue: video_queue,
      video_queue_controls: video_queue_controls
    } = params
    {:noreply,
    socket
      |> assign(:player, player)
      |> assign(:player_controls, player_controls)
      |> assign(:video_queue, video_queue)
      |> assign(:video_queue_controls, video_queue_controls)
      |> push_event("video_sorted_to_queue", %{pos: sorted_video_position})}
  end

  def handle_info({:player_signal_current_time, %{time: time}}, socket) do
    %{player: player} = socket.assigns
    {:noreply,
    socket
      |> assign(:player, Player.update(player, %{time: time}))}
  end

  def handle_info({:receive_messages, %{messages: messages}}, socket) do
    {:noreply,
      socket
      |> assign(:messages, messages)
      |> push_event("receive_new_message", %{})
    }
  end

  def handle_info({:username_changed, %{uuid: uuid, username: username}}, %{assigns: %{slug: slug}} = socket) do
    Presence.update(self(), "room:" <> slug, uuid, fn m ->
      Map.merge(m, %{username: username})
    end)

    {:noreply, socket}
  end

  def handle_info({:update_socket, %{room: room}}, socket) do
    {:noreply, socket
      |> assign(:room, room)
      |> assign(:room_changeset, Ecto.Changeset.change(room))}
  end

  @impl true
  def handle_event("player_signal_ready", _, socket) do
    %{player: player, room: room, user: user} = socket.assigns

    presence = Organizer.list_filtered_present(room.slug, user.uuid)

    case presence do
      []  ->
        %{video_queue: video_queue} = socket.assigns
        case video_queue do
          [] ->
            {:noreply,
              socket
              |> assign(:player_controls, Player.get_controls_state(player))}
          [{v, _}|_vs]  ->
            player = Player.update(player, %{video_id: v.video_id, previous_id: v.previous, next_id: v.next})
            {:noreply,
              socket
              |> assign(:video_queue, video_queue)
              |> assign(:player, player)
              |> assign(:player_controls, Player.get_controls_state(player))
              |> push_event("receive_player_state", Player.create_response(player))}
        end
      _xs ->
        Organizer.subscribe(:request_initial_state, socket.assigns.slug)
        # Tells every node the requester node needs an initial state
        :ok = Phoenix.PubSub.broadcast_from(
          LiveDj.PubSub,
          self(),
          "room:" <> socket.assigns.slug,
          {:request_initial_state, %{}}
        )
        {:noreply, socket}
    end
  end

  def handle_event("player_signal_video_ended", _params, socket) do
    %{player: player, video_queue: video_queue} = socket.assigns
    %{video_id: current_video_id} = player

    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    next_video = Queue.get_next_video(video_queue, current_video_id)

    case next_video do
      nil ->
        player = Player.update(player, %{state: "stopped", time: 0})

        {:noreply,
          socket
          |> assign(:player, player)
          |> assign(:player_controls, Player.get_controls_state(player))}
      video ->
        %{messages: messages} = socket.assigns
        %{video_id: video_id} = video

        player_props = %{video_id: video_id, time: 0, state: "playing"}
        player = Player.update(player, player_props)
        message = Chat.create_message(:track_notification, %{
          video: next_video
        })
        messages = messages ++ [message]

        {:noreply,
          socket
          |> assign(:messages, messages)
          |> assign(:player, player)
          |> assign(:player_controls, Player.get_controls_state(player))
          |> push_event("receive_player_state", Player.create_response(player))
          |> push_event("receive_notification", Notifications.create(:play_video, next_video))}
    end
  end

  @impl true
  def handle_event("remove_track", params, socket) do
    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:remove_track, %{video_id: params["video_id"]}}
    )
    {:noreply, socket}
  end

  @impl true
  def handle_event("player_signal_sort_video", %{"from" => from, "to" => to}, socket) do
    %{
      player: player,
      video_queue: video_queue,
      video_queue_controls: video_queue_controls
    } = socket.assigns

    {video, queue} = Queue.take_from_indexed_queue(video_queue, from)

    video_queue = queue
    |> List.insert_at(to, video)
    |> Enum.with_index()
    |> Queue.link_tracks(from, to)

    {%{previous: previous, next: next}, _} = Enum.find(video_queue, fn {v,_} ->
      v.video_id == player.video_id
    end)

    player = Player.update(player, %{previous_id: previous, next_id: next})

    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:player_signal_sort_video, %{
        player: player,
        player_controls: Player.get_controls_state(player),
        video_queue: video_queue,
        video_queue_controls: Queue.mark_as_unsaved(video_queue_controls),
        sorted_video_position: to+1}}
    )
    {:noreply, socket}
  end

  @impl true
  def handle_event("player_signal_play_by_id", params, socket) do
    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:player_signal_play_by_id, %{video_id: params["video_id"]}}
    )
    {:noreply, socket}
  end

  @impl true
  def handle_event(
    "search",
    %{"search_field" => %{"query" => query}},
    %{assigns: %{video_queue: video_queue}} = socket
  ) do
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    opts = [maxResults: 25]
    {:ok, search_result, _pagination_options} = Tubex.Video.search_by_query(query, opts)
    search_result = Enum.map(search_result, fn search ->
      video = Video.from_tubex_video(search)
      Video.update(video, %{is_queued: Queue.is_queued(video, video_queue)}) end)
    {:noreply,
      socket
      |> assign(:search_result, search_result)
      |> push_event("receive_search_completed_signal", %{})}
  end

  @impl true
  def handle_event("add_to_queue", selected_video, %{assigns: assigns} = socket) do
    %{
      search_result: search_result,
      video_queue: video_queue,
      video_queue_controls: video_queue_controls,
      user: user
    } = assigns

    selected_video = Enum.find(
      search_result,
      fn search -> search.video_id == selected_video["video_id"] end
    ) |> Video.assign_user(user)
    video_queue = video_queue
      |> Enum.map(fn {v, _} -> v end)
      |> Queue.add_to_queue(selected_video)

    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:add_to_queue, %{
        updated_video_queue: video_queue,
        video_queue_controls: Queue.mark_as_unsaved(video_queue_controls),
        added_video_position: length(video_queue)}}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("player_signal_current_time", current_time, socket) do
    %{room: room, user: %{uuid: uuid}} = socket.assigns

    case uuid == room.video_tracker do
      true ->
        Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> socket.assigns.slug,
          {:player_signal_current_time, %{time: current_time}}
        )
        {:noreply, socket}
      false ->
        {:noreply, socket}
    end
  end

  def handle_event("show_chat", _, socket) do
    {:noreply, socket |> assign(:current_tab, "chat")}
  end

  def handle_event("show_queue", _, socket) do
    {:noreply, socket |> assign(:current_tab, "video_queue")}
  end

  def handle_event("show_search", _, socket) do
    {:noreply, socket |> assign(:current_tab, "video_search")}
  end

  def handle_event("sections_group_show_chat", _, socket) do
    {:noreply, socket |> assign(:sections_group_tab, "chat")}
  end

  def handle_event("sections_group_show_peers", _, socket) do
    {:noreply, socket |> assign(:sections_group_tab, "peers")}
  end

  defp handle_video_tracker_activity(slug, presence, %{leaves: leaves}) do
    room = Organizer.get_room(slug)
    video_tracker = room.video_tracker

    case video_tracker in Map.keys(leaves) do
      false -> room
      true  ->
        case presence do
          [] ->
            {:ok, updated_room} = Organizer.update_room(room, %{video_tracker: ""})
            updated_room
          [p|_ps] ->
            {:ok, updated_room} = Organizer.update_room(room, %{video_tracker: p.uuid})
            updated_room
        end
    end
  end

  defp assign_tracker(socket, room) do
    current_user = socket.assigns.user.uuid
    case Organizer.list_filtered_present(room.slug, current_user) do
      []  ->
        {:ok, updated_room} = Organizer.update_room(room, %{video_tracker: current_user})
        socket
        |> assign(:room, updated_room)
      _xs ->
        socket
        |> assign(:room, room)
    end
  end
end
