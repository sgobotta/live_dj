defmodule LivedjWeb.PlayerControlsLiveTest do
  @moduledoc false
  use LivedjWeb.ConnCase

  import Phoenix.LiveViewTest
  import Livedj.SessionsFixtures

  alias Livedj.Sessions.{Channels, Player}

  test "pushes a track_changed event whenever the player loads a new track",
       %{conn: conn} do
    room = room_fixture()
    user_id = Ecto.UUID.generate()

    {:ok, view, _html} =
      live_isolated(conn, LivedjWeb.PlayerControlsLive,
        session: %{
          "id" => room.id,
          "user_id" => user_id,
          "display_name" => "Tester"
        }
      )

    player = %Player{
      id: room.id,
      state: :idle,
      media_id: "some_external_id",
      media_thumbnail_url: "some_thumbnail_url",
      title: "some title",
      channel: "some channel"
    }

    :ok = Channels.broadcast_player_load_media!(room.id, player)

    assert_push_event(view, "track_changed", %{
      title: "some title",
      channel: "some channel",
      thumbnail: "some_thumbnail_url"
    })
  end

  test "play/pause control keeps a stable id across state changes",
       %{conn: conn} do
    room = room_fixture()
    user_id = Ecto.UUID.generate()

    {:ok, view, _html} =
      live_isolated(conn, LivedjWeb.PlayerControlsLive,
        session: %{
          "id" => room.id,
          "user_id" => user_id,
          "display_name" => "Tester"
        }
      )

    player = %Player{
      id: room.id,
      state: :idle,
      media_id: "some_external_id",
      media_thumbnail_url: "some_thumbnail_url",
      title: "some title",
      channel: "some channel"
    }

    :ok = Channels.broadcast_player_load_media!(room.id, player)

    idle_html = render(view)
    assert idle_html =~ ~s(id="play-pause-btn")
    assert idle_html =~ ~s(phx-click="on_play_click")
    refute idle_html =~ ~s(phx-click="on_pause_click")

    :ok =
      Channels.broadcast_player_play!(room.id, %{player | state: :playing})

    playing_html = render(view)
    assert playing_html =~ ~s(id="play-pause-btn")
    assert playing_html =~ ~s(phx-click="on_pause_click")
    refute playing_html =~ ~s(phx-click="on_play_click")

    :ok =
      Channels.broadcast_player_pause!(room.id, %{player | state: :paused})

    paused_html = render(view)
    assert paused_html =~ ~s(id="play-pause-btn")
    assert paused_html =~ ~s(phx-click="on_play_click")
    refute paused_html =~ ~s(phx-click="on_pause_click")
  end
end
