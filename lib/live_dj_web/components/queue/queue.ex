defmodule LiveDjWeb.Components.Queue do
  @moduledoc """
  Responsible for displaying the queue
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Accounts.Permission

  @impl true
  def update(assigns, socket) do
    %{
      user_room_group: %{permissions: permissions},
      room_management: room_management
    } = assigns

    is_managed = room_management != "free"

    queue_permissions = %{
      can_remove_track: !is_managed or Permission.has_permission(permissions, "can_remove_track")
    }

    {:ok,
     socket
     |> assign(:queue_permissions, queue_permissions)
     |> assign(assigns)}
  end

  @impl true
  def handle_event("remove_track", params, socket) do
    :ok =
      Phoenix.PubSub.broadcast(
        LiveDj.PubSub,
        "room:" <> socket.assigns.slug,
        {:remove_track, %{video_id: params["video_id"]}}
      )

    {:noreply, socket}
  end

  def render_remove_button(
        current_video_id,
        video_id,
        video_index,
        can_remove_track,
        assigns
      ) do
    event =
      if can_remove_track do
        "remove_track"
      else
        ""
      end

    is_current_track = current_video_id == video_id

    case !is_current_track and can_remove_track do
      true ->
        id = "remove-video-button-#{video_index}"

        ~H"""
          <a
            class="btn"
            id={id}
            phx-click={event}
            phx-value-video_id={video_id}
            phx-target={assigns}
          >
            <i class="fas fa-trash trash clickeable"></i>
          </a>
        """

      false ->
        nil
    end
  end
end
