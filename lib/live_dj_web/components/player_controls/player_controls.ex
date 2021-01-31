defmodule LiveDjWeb.Components.PlayerControls do
  @moduledoc """
  Responsible for displaying the player controls
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Organizer.Player
  alias LiveDj.Organizer.Queue

  def update(assigns, socket) do

    %{user_room_group: %{permissions: permissions}} = assigns

    player_permissions = %{
      can_play_track:  has_permission(permissions, "can_play_track"),
      can_pause_track: has_permission(permissions, "can_pause_track"),
      can_play_next_track: has_permission(permissions, "can_play_next_track"),
      can_play_previous_track: has_permission(permissions, "can_play_previous_track"),
    }

    {:ok,
      socket
      |> assign(:player_permissions, player_permissions)
      |> assign(assigns)
    }
  end

  defp has_permission(permissions, permission) do
    Enum.any?(permissions, fn p -> p.codename == permission end)
  end

  def handle_event("player_signal_playing", _params,
    %{assigns: %{player_permissions: %{can_play_track: true}}} = socket
  ) do
    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:player_signal_playing, %{state: "playing"}}
    )
    {:noreply, socket}
  end

  def handle_event("player_signal_playing", _params,
    %{assigns: %{player_permissions: %{can_play_track: false}}} = socket
  ) do
    {:noreply, socket}
  end

  def handle_event("player_signal_paused", _params, socket) do
    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:player_signal_paused, %{state: "paused"}}
    )
    {:noreply, socket}
  end

# ===========================================================================
#
# Very similar functions, refactor if not used for a specific task
#

  def handle_event("player_signal_play_previous", _params, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    %{video_id: current_video_id} = player
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    previous_video = Queue.get_previous_video(video_queue, current_video_id)

    case previous_video do
      nil -> {:noreply, socket}
      video ->
        %{slug: slug} = socket.assigns
        %{video_id: video_id} = video
        player = Player.update(player, %{video_id: video_id, time: 0, state: "playing", previous_id: video.previous, next_id: video.next})
        player_controls = Player.get_controls_state(player)

        :ok = Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> slug,
          {:player_signal_play_previous, %{player: player, player_controls: player_controls}}
        )

        {:noreply, socket}
    end
  end

  def handle_event("player_signal_play_next", _params, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    %{video_id: current_video_id} = player
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    next_video = Queue.get_next_video(video_queue, current_video_id)

    case next_video do
      nil -> {:noreply, socket}
      video ->
        %{slug: slug} = socket.assigns
        %{video_id: video_id} = video
        player = Player.update(player, %{video_id: video_id, time: 0, state: "playing", previous_id: video.previous, next_id: video.next})
        player_controls = Player.get_controls_state(player)

        :ok = Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> slug,
          {:player_signal_play_next, %{player: player, player_controls: player_controls}}
        )

        {:noreply, socket}
    end
  end

#
# ===========================================================================

  def render_player_control_button(
    "play-controls", player_state, player_controls,
    {can_play_track, can_pause_track},
    assigns
  ) do
    %{
      pause_button_state: pause_button_state,
      play_button_state: play_button_state
    } = player_controls
    is_player_loading = pause_button_state == "disabled" && play_button_state == "disabled"
    {play_button_class, anchor_class} = case is_player_loading do
      true -> {"show_loader_control_button player-control-spin", ""}
      false -> case player_state do
        "paused" ->  {"show_play_control_button",  if can_play_track  do "" else "disabled" end}
        "stopped" -> {"show_play_control_button",  if can_play_track  do "" else "disabled" end}
        "playing" -> {"show_pause_control_button", if can_pause_track do "" else "disabled" end}
      end
    end
    player_event = case player_state do
      "paused"  -> if can_play_track do "player_signal_playing" else "" end
      "stopped" -> if can_play_track do "player_signal_playing" else "" end
      "playing" -> if can_pause_track do "player_signal_paused" else "" end
      _         -> ""
    end

    ~L"""
      <a class="<%= anchor_class %>" phx-click="<%= player_event %>" phx-target="<%= assigns %>">
        <%= render_svg(
          "icons/player/play-controls",
          "h-12 w-12 player-control clickeable #{play_button_class}"
        ) %>
      </a>
    """
  end

  def render_player_control_button(button, event_name, button_state, has_permission, assigns) do
    %{link_props: link_props, svg_classes: svg_classes} = case button_state do
      "disabled" ->
        %{
          link_props: %{class: "disabled", phx_click: "", phx_target: nil},
          svg_classes: "",
        }
      _ ->
        %{
          link_props: %{
            class: if has_permission do "" else "disabled" end,
            phx_click: if has_permission do event_name else "" end,
            phx_target: if has_permission do assigns else nil end,
          },
          svg_classes: "player-control clickeable",
        }
    end

    ~L"""
      <a
        class="<%= link_props.class %>"
        phx-click="<%= link_props.phx_click %>"
        phx-target="<%= link_props.phx_target %>"
      >
        <%= render_svg("icons/player/#{button}", "h-12 w-12 #{svg_classes}") %>
      </a>
    """
  end

  defp render_svg(icon, classes) do
    PhoenixInlineSvg.Helpers.svg_image(LiveDjWeb.Endpoint, icon, class: classes)
  end
end
