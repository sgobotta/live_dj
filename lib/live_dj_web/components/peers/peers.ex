defmodule LiveDjWeb.Components.Peers do
  @moduledoc """
  Responsible for displaying information about other peers
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Repo
  alias LiveDj.Accounts
  alias LiveDj.Organizer
  alias LiveDj.Organizer.UserRoom

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(:connected_users, assigns.connected_users)
      |> assign(assigns)
    }
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
      nil -> {:noreply, socket}
      user ->
        %{assigns: %{room: %{id: room_id, slug: slug}}} = socket
        user_id = hd(user.metas).user_id
        group_id = Accounts.get_group_by_codename("room-collaborator").id
        {:ok, user_room} = Organizer.create_user_room(%{
          user_id: user_id,
          room_id: room_id,
          group_id: group_id
        })
        %UserRoom{group: group} = Repo.preload(user_room, [:group])

        topic = "room:" <> slug
        :ok = Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          topic,
          {:presence_group_changed, %{topic: topic, uuid: uuid, group: group}}
        )

        {:noreply, socket}
    end
  end

  def handle_event("remove_room_collaborator", %{"presence_id" => uuid}, socket) do
    %{assigns: %{connected_users: connected_users}} = socket
    case Enum.find(connected_users, fn user -> user.uuid == uuid end) do
      nil -> {:noreply, socket}
      user ->
        %{assigns: %{room: %{id: room_id, slug: slug}}} = socket
        user_id = hd(user.metas).user_id
        user_room = Organizer.get_user_room_by(%{
          user_id: user_id,
          room_id: room_id
        })
        {:ok, _user_room} = Organizer.delete_user_room(user_room)
        group = %{codename: "registered-user", name: "Registered  user"}

        topic = "room:" <> slug
        :ok = Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          topic,
          {:presence_group_changed, %{topic: topic, uuid: uuid, group: group}}
        )

        {:noreply, socket}
    end
  end

  def render_assign_privileges_button(user_room_group, peer_metas, target) do
    %{uuid: uuid, metas: metas} = peer_metas
    peer_metas = hd(metas)

    case peer_metas.user_room_group.codename do
      "anonymous-user" -> ""
      peer_group ->
        case user_room_group.codename do
          "room-admin" ->
            case peer_group do
              "room-collaborator" ->
                button_params = %{
                  event: "remove_room_collaborator",
                  classes: "show-remove-button",
                  presence_id: uuid,
                  target: target
                }
                render_privileges_button(button_params)
              "registered-user" ->
                button_params = %{
                  event: "add_room_collaborator",
                  classes: "show-add-button",
                  presence_id: uuid,
                  target: target
                }
                render_privileges_button(button_params)
              _ -> ""
            end
          _ -> ""
      end
    end
  end

  def render_privileges_button(%{event: event, classes: classes, presence_id: presence_id, target: assigns}) do
    ~L"""
      <button
        class="svg-button-container"
        phx-click="<%= event %>"
        phx-target="<%= assigns %>"
        phx-value-presence_id="<%= presence_id %>"
      >
        <%= PhoenixInlineSvg.Helpers.svg_image(
          LiveDjWeb.Endpoint,
          "icons/peers/add",
          class: "h-8 w-8 clickeable #{classes}"
        ) %>
      </button>
    """
  end
end
