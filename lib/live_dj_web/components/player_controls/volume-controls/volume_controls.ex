defmodule LiveDjWeb.Components.VolumeControls do
  @moduledoc """
  Responsible for displaying the volume controls
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Organizer.VolumeControls

  @impl true
  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end

  @impl true
  def handle_event("player_signal_toggle_volume", _params, socket) do
    %{
      volume_controls: volume_controls,
      slug: slug,
      user: %{uuid: uuid},
    } = socket.assigns
    %{is_muted: is_muted, volume_level: volume_level} = volume_controls

    volume_level = case !is_muted do
      true -> 0
      false -> volume_level
    end

    volume_icon = VolumeControls.get_volume_icon(volume_level)

    params = %{
      is_muted: !is_muted,
      volume_icon: volume_icon}
    volume_controls = VolumeControls.update(volume_controls, params)
    socket = assign(socket, :volume_controls, volume_controls)

    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> slug,
      {:volume_level_changed, %{uuid: uuid, volume_level: volume_level, volume_icon: volume_icon}}
    )

    case is_muted do
      true ->
        {:noreply,
          socket
          |> push_event("receive_unmute_signal", %{})}
      false ->
        {:noreply,
          socket
          |> push_event("receive_mute_signal", %{})}
    end
  end

  @impl true
  def handle_event(
    "volume_level_changed",
    %{"volume_change" => volume_level},
    socket
  ) do
    {volume_level, _} = Integer.parse(volume_level)
    %{slug: slug,
      user: %{uuid: uuid},
      volume_controls: volume_controls} = socket.assigns

    volume_icon = VolumeControls.get_volume_icon(volume_level)

    %{is_muted: is_muted} = volume_controls
    socket = case is_muted do
      true -> push_event(socket, "receive_unmute_signal", %{})
      _ -> socket
    end

    is_volume_down = VolumeControls.get_state_by_level(volume_level)

    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> slug,
      {:volume_level_changed, %{uuid: uuid, volume_level: volume_level, volume_icon: volume_icon}}
    )

    params = %{
      is_muted: is_volume_down,
      volume_icon: volume_icon,
      volume_level: volume_level}
    volume_controls = VolumeControls.update(volume_controls, params)

    {:noreply,
      socket
      |> push_event("receive_player_volume", %{level: volume_level})
      |> assign(:volume_controls, volume_controls)}
  end
end
