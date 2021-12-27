defmodule LiveDjWeb.ChatTests do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Repo

  import LiveDj.DataCase
  import LiveDj.OrganizerFixtures
  import LiveDj.ViewCase
  import Phoenix.LiveViewTest

  @search_video_form_id "#search-video-form"

  def save_queue(view) do
    # Asserts the save queue button exists
    assert has_button(view, "save_queue")
    # Saves the queue
    click(view, "save_queue")
    # Asserts the save button isn't enabled
    refute has_button(view, "save_queue")
  end

  def search_video(view, search_query) do
    # Simulates a search video interaction
    view
    |> element(@search_video_form_id)
    |> render_change(%{search_field: %{query: search_query}})

    view
    |> element(@search_video_form_id)
    |> render_submit(%{})

    assert_push_event(view, "receive_search_completed_signal", %{})
  end

  describe "Video player notifications" do
    @player_syncing_hook_id "#player-syncing-data"

    setup(%{conn: conn}) do
      %{group: group} = show_live_setup()

      %{conn: conn, group: group |> Repo.preload([:permissions])}
    end

    test "As a Chat I can receive video player messages of a Registered User that adds a track",
         %{conn: conn, group: group} do
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} =
        user_room_fixture(
          %{
            is_owner: false,
            group_id: group.id
          },
          %{},
          %{queue: []}
        )

      # Creates a new authenticated connection
      conn = log_in_user(conn, user)
      url = "/room/#{room.slug}"
      {:ok, view, _html} = live(conn, url)
      # Simulates a search video interaction
      search_query = "some video search"
      search_video(view, search_query)

      view
      |> element("#search-element-button-1")
      |> render_click()

      view
      |> element("#search-element-button-2")
      |> render_click()

      pos = length(room.queue) + 1
      assert_push_event(view, "video_added_to_queue", %{pos: ^pos})
      assert_push_event(view, "receive_player_state", %{})
      # Triggers a notification
      view
      |> element(@player_syncing_hook_id)
      |> render_hook(:player_signal_video_ended, %{})

      assert_push_event(view, "receive_player_state", %{})

      assert render(view) =~
               "<div><p class=\"chat-message\"><span class=\"timestamp timestamp-message\">\n"

      assert render(view) =~
               "<span class=\"use-prompt\"><span class=\"chat-username highlight-username\">info</span></span><span class=\"chat-text \">  Playing\n  <span class=\"highlight-video-title\">"

      assert render(view) =~
               "</span>,\n  added by <span class=\"font-bold highlight-username\">#{
                 user.username
               }</span>"

      assert render(view) =~ "</span></span></p></div></div>"
    end

    test "As a Chat I can receive video player messages of a Visitor User that adds a track",
         %{group: group} do
      # Associates a group id to a new user for a new room
      %{room: room, user: _user, user_room: _user_room} =
        user_room_fixture(
          %{
            is_owner: false,
            group_id: group.id
          },
          %{},
          %{queue: []}
        )

      # Creates a new unauthenticated connection
      conn = build_conn()
      url = "/room/#{room.slug}"
      {:ok, view, _html} = live(conn, url)
      # Simulates a search video interaction
      search_query = "some video search"
      search_video(view, search_query)

      view
      |> element("#search-element-button-1")
      |> render_click()

      view
      |> element("#search-element-button-2")
      |> render_click()

      pos = length(room.queue) + 1
      assert_push_event(view, "video_added_to_queue", %{pos: ^pos})
      assert_push_event(view, "receive_player_state", %{})
      # Triggers a notification
      view
      |> element(@player_syncing_hook_id)
      |> render_hook(:player_signal_video_ended, %{})

      assert_push_event(view, "receive_player_state", %{})

      assert render(view) =~
               "<div><p class=\"chat-message\"><span class=\"timestamp timestamp-message\">\n"

      assert render(view) =~
               "<span class=\"use-prompt\"><span class=\"chat-username highlight-username\">info</span></span><span class=\"chat-text \">  Playing\n  <span class=\"highlight-video-title\">"

      assert render(view) =~
               "</span>,\n  added by <span class=\"font-bold highlight-username\">"

      assert render(view) =~ "</span></span></p></div></div>"
    end
  end
end
