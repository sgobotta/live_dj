defmodule LiveDjWeb.ShowRoomTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Repo

  import LiveDj.AccountsFixtures
  import LiveDj.OrganizerFixtures
  import LiveDj.DataCase
  import Phoenix.LiveViewTest

  describe "ShowLive user room groups assignation" do

    setup(%{conn: conn}) do
      %{group: group} = show_live_setup()

      %{conn: conn, group: group |> Repo.preload([:permissions])}
    end

    test "As a registered User When I belong to a group associated to a room I obtain those group permissions",
      %{conn: conn, group: group}
    do
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      })
      conn = log_in_user(conn, user)

      %{assigns: assigns} = _conn = get(conn, "/room/#{room.slug}")

      refute assigns.visitor
      assert assigns.user_room_group.permissions == group.permissions
    end

    test "As a registered User When I don't belong to a group associated to a room I obtain no permissions",
      %{conn: conn}
    do
      %{conn: conn, user: _user} = register_and_log_in_user(%{conn: conn})
      room = room_fixture()
      %{assigns: assigns} = _conn = get(conn, "/room/#{room.slug}")

      refute assigns.visitor
      assert assigns.user_room_group.permissions == []
    end

    test "As a visitor User I obtain no permissions", %{conn: conn} do
      room = room_fixture()
      %{assigns: assigns} = _conn = get(conn, "/room/#{room.slug}")

      assert assigns.visitor
      assert assigns.user_room_group.permissions == []
    end
  end

  describe "ShowLive chat behaviour" do

    @new_message_form_id "#new-message"
    @new_message_form_input_id "#new-message-input"

    setup(%{conn: conn}) do
      %{group: group} = show_live_setup()

      %{conn: conn, group: group |> Repo.preload([:permissions])}
    end

    test "As a Registered user I can communicate with other peers by typing a messag in the chat box",
      %{conn: conn, group: group}
    do
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      })
      # Creates a new authenticated connection
      owner_conn = log_in_user(conn, user)
      {:ok, view, _html} = live(owner_conn, "/room/#{room.slug}")
      # Simulates a chat interaction
      view
        |> element(@new_message_form_id)
        |> render_change(%{})
      view
        |> element(@new_message_form_input_id)
        |> render_blur(%{value: "Hi?"})
      view
        |> element(@new_message_form_id)
        |> render_submit(%{submit: %{message: "Hello!"}})
      # Establishes a connection
      %{assigns: %{user: user}} = get(owner_conn, "/room/#{room.slug}")

      refute render(view) =~ "Hi?"
      assert render(view) =~ "Hello!"
      assert render(view) =~ user.username
    end
  end

  describe "ShowLive search video behaviour" do

    @search_video_form_id "#search-video-form"

    setup(%{conn: conn}) do
      %{group: group} = show_live_setup()

      %{conn: conn, group: group |> Repo.preload([:permissions])}
    end

    test "As a registered User I can search and add a video to a queue",
      %{conn: conn, group: group}
    do
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      })
      # Creates a new authenticated connection
      owner_conn = log_in_user(conn, user)
      {:ok, view, _html} = live(owner_conn, "/room/#{room.slug}")
      # Simulates a search video interaction
      search_query = "some video search"
      view
        |> element(@search_video_form_id)
        |> render_change(%{search_field: %{query: search_query}})
      view
        |> element(@search_video_form_id)
        |> render_submit(%{})
      assert_push_event view, "receive_search_completed_signal", %{}
      # Adds a video to the queue
      view
        |> element("#search-element-button-1")
        |> render_click()
      pos = length(room.queue) + 1
      assert_push_event view, "video_added_to_queue", %{pos: ^pos}
      assert_push_event view, "receive_player_state", %{}
    end

    test "As a registered User I can search and add a video to an empty queue",
      %{conn: conn, group: group}
    do
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      }, %{}, %{queue: []})
      # Creates a new authenticated connection
      owner_conn = log_in_user(conn, user)
      {:ok, view, _html} = live(owner_conn, "/room/#{room.slug}")
      # Simulates a search video interaction
      search_query = "some video search"
      view
        |> element(@search_video_form_id)
        |> render_change(%{search_field: %{query: search_query}})
      view
        |> element(@search_video_form_id)
        |> render_submit(%{})
      assert_push_event view, "receive_search_completed_signal", %{}
      # Adds a video to the queue
      view
        |> element("#search-element-button-1")
        |> render_click()
      pos = length(room.queue) + 1
      assert_push_event view, "video_added_to_queue", %{pos: ^pos}
      assert_push_event view, "receive_player_state", %{}
    end
  end

  describe "ShowLive video queue behaviour - Registered users" do

    @play_video_button_id "#play-button-?"
    @remove_video_button_id "#remove-video-button-?"

    setup(%{conn: conn}) do
      %{group: group} = show_live_setup()
      group = group |> Repo.preload([:permissions])
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      })
      %{conn: log_in_user(conn, user), room: room}
    end

    test "As a Registered User I can play a video from a queue",
      %{conn: conn, room: room}
    do
      {:ok, view, _html} = live(conn, "/room/#{room.slug}")
      video_index = Enum.random(0..length(room.queue)-1)
      element_id = String.replace(@play_video_button_id, "?", "#{video_index}")
      # Finds the element in the DOM
      element = view |> element(element_id)
      # Refutes the element is the one that is being played
      refute element |> render() =~ "current-video"
      # Clicks the play button
      element |> render_click()
      # Asserts the element is the one that is being played
      assert view
      |> element(element_id)
      |> render() =~ "current-video"
    end

    test "As a Registered User I can remove a video from a queue",
      %{conn: conn, room: room}
    do
      {:ok, view, _html} = live(conn, "/room/#{room.slug}")
      video_index = length(room.queue) - 1
      element_id = String.replace(@remove_video_button_id,
        "?", "#{video_index}"
      )
      # Finds the element in the DOM
      element = view |> element(element_id)
      # Asserts the element exists so that it can be deleted
      assert element |> has_element?()
      # Clicks the remove button
      render_click(element)
      # Asserts the element has been removed from the DOM
      refute view |> element(element_id) |> has_element?()
    end

    test "As a Registered User I can't remove a video that's currently being played",
      %{conn: conn, room: room}
    do
      {:ok, view, _html} = live(conn, "/room/#{room.slug}")
      video_index = Enum.random(0..length(room.queue)-1)
      element_id = String.replace(@play_video_button_id, "?", "#{video_index}")
      # Finds the element in the DOM
      element = view |> element(element_id)
      # Refutes the element is the one that is being played
      refute element |> render() =~ "current-video"
      # Clicks the play button
      element |> render_click()
      # Asserts the element is the one that is being played
      assert view
      |> element(element_id)
      |> render() =~ "current-video"
      # Refutes the remove button exists for this element
      remove_element_id = String.replace(@remove_video_button_id, "?",
        "#{video_index}")
      refute view |> element(remove_element_id) |> has_element?()
    end
  end

  describe "ShowLive volume controls behaviour" do
    @volume_slider_id "#volume-controls-slider"
    @volume_toggle_id "#volume-controls-toggle"
    @rendered_target ".volume-control-container"

    setup(%{conn: conn}) do
      %{group: group} = show_live_setup()
      group = group |> Repo.preload([:permissions])
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      })
      %{conn: log_in_user(conn, user), room: room}
    end

    test "As a User I can change the volume level", %{conn: conn, room: room} do
      {:ok, view, _html} = live(conn, "/room/#{room.slug}")
      assert view |> element(@volume_slider_id) |> has_element?()
      # Volume is at it's maximum level by default, so that we assert the
      # speaker-4 class is used.
      assert view |> element(@rendered_target) |> render() =~ "speaker-4"
      # Changes the volume level to 70
      rendered_view = view
      |> element(@volume_slider_id)
      |> render_change(%{"volume" => %{"change" => 70}})
      # Volume lowered to 70 so that we assert the speaker-3 class is used
      refute rendered_view =~ "speaker-4"
      assert rendered_view =~ "speaker-3"
      assert_push_event view, "receive_player_volume", %{level: 70}
      # Changes the volume level to 40
      rendered_view = view
      |> element(@volume_slider_id)
      |> render_change(%{"volume" => %{"change" => 40}})
      # Volume lowered to 69 so that we assert the speaker-2 class is used
      refute rendered_view =~ "speaker-3"
      assert rendered_view =~ "speaker-2"
      assert_push_event view, "receive_player_volume", %{level: 40}
      # Changes the volume level to 10
      rendered_view = view
      |> element(@volume_slider_id)
      |> render_change(%{"volume" => %{"change" => 10}})
      # Volume lowered to 10 so that we assert the speaker-1 class is used
      refute rendered_view =~ "speaker-2"
      assert rendered_view =~ "speaker-1"
      assert_push_event view, "receive_player_volume", %{level: 10}
      # Changes the volume level to 9
      rendered_view = view
      |> element(@volume_slider_id)
      |> render_change(%{"volume" => %{"change" => 0}})
      # Volume lowered to 0 so that we assert the speaker-0 class is used
      refute rendered_view =~ "speaker-1"
      assert rendered_view =~ "speaker-0"
      assert_push_event view, "receive_player_volume", %{level: 0}
      # Changes the volume level back to 70
      rendered_view = view
      |> element(@volume_slider_id)
      |> render_change(%{"volume" => %{"change" => 70}})
      # Volume lowered to 70 so that we assert the speaker-3 class is used
      refute rendered_view =~ "speaker-4"
      assert rendered_view =~ "speaker-3"
      assert_push_event view, "receive_player_volume", %{level: 70}
    end

    test "As a user I can toggle the volume level", %{conn: conn, room: room} do
      {:ok, view, _html} = live(conn, "/room/#{room.slug}")
      # Asserts The volume toggle button exists
      assert view |> element(@volume_toggle_id) |> has_element?()
      # Changes the volume level to 70 just to avoid using the default volume
      # value
      rendered_view = view
      |> element(@volume_slider_id)
      |> render_change(%{"volume" => %{"change" => 70}})
      # Volume lowered to 70 so that we assert the speaker-3 class is used
      refute rendered_view =~ "speaker-4"
      assert rendered_view =~ "speaker-3"
      assert_push_event view, "receive_player_volume", %{level: 70}
      # Clicks the toggle button to get a muted state
      rendered_view = view |> element(@volume_toggle_id) |> render_click()
      refute rendered_view =~ "speaker-3"
      assert rendered_view =~ "speaker-0"
      assert_push_event view, "receive_mute_signal", %{}
      # Clicks the toggle button again to get to our initial state of level 70
      rendered_view = view |> element(@volume_toggle_id) |> render_click()
      refute rendered_view =~ "speaker-0"
      assert rendered_view =~ "speaker-3"
      assert_push_event view, "receive_unmute_signal", %{}
    end
  end

  describe "ShowLive room settings behaviour" do
    @room_settings_modal_button_id "#aside-room-settings-modal-button"
    @username_edit_form_id "#username-edit-form"
    @user_registration_form_id "#user-registration-form"

    setup(%{conn: conn}) do
      %{group: group} = show_live_setup()
      group = group |> Repo.preload([:permissions])
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      })
      %{conn: log_in_user(conn, user), room: room}
    end

    test "As a Registered User I can change my username",
      %{conn: conn, room: room}
    do
      {:ok, view, _html} = live(conn, "/room/#{room.slug}")
      # Opens the room settings modal
      view |> element(@room_settings_modal_button_id) |> render_click()
      # Asserts The username edit form exists
      assert view |> element(@username_edit_form_id) |> has_element?()
      # Fills in the form and clicks the submit button
      new_name = "wasabibrownies"
      params = %{
        "user" => %{"username" => new_name},
        "current_password" => valid_user_password()
      }
      view |> element(@username_edit_form_id) |> render_submit(params)
      assert view |> render() =~ new_name
    end

    test "As a Visitor User I can fill a registration form",
      %{room: room}
    do
      conn = build_conn()
      {:ok, view, _html} = live(conn, "/room/#{room.slug}")
      # Opens the room settings modal
      view |> element(@room_settings_modal_button_id) |> render_click()
      # Asserts The username edit form exists
      assert view
      |> element(@user_registration_form_id) |> has_element?()
      # Fills in the form and clicks the submit button
      new_name = "wasabibrownies"
      params = %{
        "user" => %{"username" => new_name, "terms" => true},
      }

      # FIXME: it's not testing anything.
      # There's currently no way to test phx_trigger_action.
      view
      |> form(@user_registration_form_id, params)
      |> render_submit()
    end
  end

  describe "ShowLive peers section behaviour" do

    @add_collaborator_button_id "#add_room_collaborator-?"
    @remove_collaborator_button_id "#remove_room_collaborator-?"

    setup(%{conn: conn}) do
      %{group: room_admin_group} = show_live_setup()
      room_admin_group = room_admin_group |> Repo.preload([:permissions])
      # Associates a group id to a new user for a new room and makes this user
      # an owner of the room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: true, group_id: room_admin_group.id
      }, %{}, %{management_type: "managed"})
      %{conn: log_in_user(conn, user), room: room}
    end

    test "As a room owner I can add and remove collaborators",
      %{conn: owner_conn, room: room}
    do
      url = "/room/#{room.slug}"
      # Registers and logs in a user
      %{conn: user_conn, user: _user} = register_and_log_in_user(
        %{conn: build_conn()})
      # Obatains the user connection uuid to get buttons ids
      %{assigns: %{user: %{uuid: user_uuid}}} = user_conn = get(
        user_conn, url)
      # Gets an owner view
      {:ok, owner_view, _html} = live(owner_conn, url)
      # Asserts the add button is available but the remove button isn't
      add_button_id = String.replace(
        @add_collaborator_button_id, "?", "#{user_uuid}")
      remove_button_id = String.replace(
        @remove_collaborator_button_id, "?", "#{user_uuid}")
      refute owner_view |> element(remove_button_id) |> has_element?()
      assert owner_view |> element(add_button_id) |> has_element?()
      # Adds a user as a collaborator
      owner_view |> element(add_button_id) |> render_click()
      # Refreshes the user connection to asserts the remove is now available but
      # the add button isn't
      %{assigns: %{user: %{uuid: user_uuid}}} = _user_conn = get(
        user_conn, url)
      add_button_id = String.replace(@add_collaborator_button_id,
        "?", "#{user_uuid}")
      remove_button_id = String.replace(@remove_collaborator_button_id,
        "?", "#{user_uuid}")
      refute owner_view |> element(add_button_id) |> has_element?()
      assert owner_view |> element(remove_button_id) |> has_element?()
      # Removes a user as a collaborator
      owner_view |> element(remove_button_id) |> render_click()
      # Refreshes the user connection to asserts the add is now available but
      # the remove button isn't
      %{assigns: %{user: %{uuid: user_uuid}}} = _user_conn = get(
        user_conn, url)
      add_button_id = String.replace(@add_collaborator_button_id,
        "?", "#{user_uuid}")
      remove_button_id = String.replace(@remove_collaborator_button_id,
        "?", "#{user_uuid}")
      assert owner_view |> element(add_button_id) |> has_element?()
      refute owner_view |> element(remove_button_id) |> has_element?()
    end
  end
end
