defmodule LiveDjWeb.Components.Peers do
  @moduledoc """
  Responsible for displaying information about other peers
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Accounts
  alias LiveDj.Notifications
  alias LiveDj.Organizer
  alias LiveDj.Organizer.UserRoom
  alias LiveDj.Repo
  alias LiveDj.Stats

  def update(assigns, socket) do
    %{room_management: room_management} = assigns
    is_managed = room_management != "free"

    {:ok,
     socket
     |> assign(:connected_users, assigns.connected_users)
     |> assign(:is_managed, is_managed)
     |> assign(assigns)}
  end

  # FIXME: Remove and refactor to use svgs
  def get_volume_icon_class(svg_icon_name) do
    case svg_icon_name do
      "speaker-4" -> "fa-volume-up"
      "speaker-3" -> "fa-volume-down"
      "speaker-2" -> "fa-volume-down"
      "speaker-1" -> "fa-volume-off"
      "speaker-0" -> "fa-volume-mute"
      _ -> "fa-volume-up"
    end
  end

  def handle_event("add_room_collaborator", %{"presence_id" => uuid}, socket) do
    %{assigns: %{connected_users: connected_users}} = socket

    case Enum.find(connected_users, fn user -> user.uuid == uuid end) do
      nil ->
        {:noreply, socket}

      user ->
        %{assigns: %{room: %{id: room_id, slug: slug}}} = socket
        user_id = hd(user.metas).user_id
        group_id = Accounts.get_group_by_codename("room-collaborator").id
        users_rooms = Organizer.list_users_rooms_by(user_id, false)

        {:ok, user_room} =
          Organizer.create_user_room(%{
            user_id: user_id,
            room_id: room_id,
            group_id: group_id
          })

        socket =
          case Stats.assoc_user_badge(
                 "rooms-collaboration",
                 user_id,
                 length(users_rooms) + 1
               ) do
            {:unchanged} ->
              socket

            {:ok, user_badge} ->
              %{badge: badge} = user_badge

              push_event(
                socket,
                "receive_notification",
                Notifications.create(
                  :receive_badge,
                  %{badge_icon: badge.icon, badge_name: badge.name}
                )
              )

            {:error} ->
              socket
          end

        %UserRoom{group: group} = Repo.preload(user_room, [:group])
        group = Repo.preload(group, [:permissions])

        topic = "room:" <> slug

        :ok =
          Phoenix.PubSub.broadcast(
            LiveDj.PubSub,
            topic,
            {:user_room_group_changed,
             %{topic: topic, user_id: user_id, uuid: uuid, group: group}}
          )

        {:noreply, socket}
    end
  end

  def handle_event("remove_room_collaborator", %{"presence_id" => uuid}, socket) do
    %{assigns: %{connected_users: connected_users}} = socket

    case Enum.find(connected_users, fn user -> user.uuid == uuid end) do
      nil ->
        {:noreply, socket}

      user ->
        %{assigns: %{room: %{id: room_id, slug: slug}}} = socket
        user_id = hd(user.metas).user_id

        user_room =
          Organizer.get_user_room_by(%{
            user_id: user_id,
            room_id: room_id
          })

        group =
          Accounts.get_group_by_codename("registered-room-visitor")
          |> Repo.preload([:permissions])

        {:ok, _user_room} =
          Organizer.update_user_room(user_room, %{
            group_id: group.id
          })

        topic = "room:" <> slug

        :ok =
          Phoenix.PubSub.broadcast(
            LiveDj.PubSub,
            topic,
            {:user_room_group_changed,
             %{topic: topic, user_id: user_id, uuid: uuid, group: group}}
          )

        {:noreply, socket}
    end
  end

  def render_assign_privileges_button(false, _user_room_group, _peer_metas, _target) do
    {:safe, ""}
  end

  def render_assign_privileges_button(true, user_room_group, peer_metas, target) do
    %{uuid: uuid, metas: metas} = peer_metas
    peer_metas = hd(metas)

    case peer_metas.group.codename do
      "anonymous-room-visitor" ->
        # Send an invite notification to register
        ""

      peer_group ->
        %{permissions: permissions} = user_room_group

        case peer_group do
          "room-collaborator" ->
            case Enum.any?(
                   permissions,
                   fn p -> p.codename == "can_remove_room_collaborators" end
                 ) do
              true ->
                button_params = %{
                  event: "remove_room_collaborator",
                  classes: "show-remove-button",
                  presence_id: uuid,
                  target: target
                }

                render_privileges_button(button_params)

              false ->
                ""
            end

          "registered-room-visitor" ->
            case Enum.any?(
                   permissions,
                   fn p -> p.codename == "can_add_room_collaborators" end
                 ) do
              true ->
                button_params = %{
                  event: "add_room_collaborator",
                  classes: "show-add-button",
                  presence_id: uuid,
                  target: target
                }

                render_privileges_button(button_params)

              false ->
                ""
            end

          _ ->
            ""
        end
    end
  end

  def render_privileges_button(%{
        event: event,
        classes: classes,
        presence_id: presence_id,
        target: assigns
      }) do
    ~H"""
      <button
        id={"#{event}-#{presence_id}"}
        class="svg-button-container"
        phx-click={event}
        phx-target={assigns}
        phx-value-presence_id={presence_id}
      >
        <%= PhoenixInlineSvg.Helpers.svg_image(
          LiveDjWeb.Endpoint,
          "icons/peers/add",
          class: "h-8 w-8 clickeable #{classes}"
        ) %>
      </button>
    """
  end

  def render_group_avatar(false, _user_room_group, _assigns) do
    {:safe, ""}
  end

  def render_group_avatar(true, user_room_group, assigns) do
    icon =
      case user_room_group do
        "room-admin" -> "🛠️"
        "room-collaborator" -> "🔧"
        _ -> ""
      end

    ~H"""
      <a><%= icon %></a>
    """
  end
end
