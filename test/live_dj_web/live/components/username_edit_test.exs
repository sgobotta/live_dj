defmodule LiveDjWeb.Components.UsernameEditTest do
  use LiveDjWeb.ConnCase, async: true

  import LiveDj.OrganizerFixtures
  import Phoenix.LiveViewTest

  describe "UsernameEdit test" do
    test "todo", %{conn: conn} do
      %{user: user} = register_and_log_in_user(%{conn: conn})
      current_user = user
      room = room_fixture()
      user = LiveDj.ConnectedUser.create_connected_user(user.username)
      user_changeset = LiveDj.Accounts.change_user_username(%LiveDj.Accounts.User{})

      component_view =
        render_component(
          LiveDjWeb.Components.Settings.UsernameEdit,
          id: "header-change-username-modal-settings-username-edit",
          current_user: current_user,
          room: room,
          user: user,
          user_changeset: user_changeset
        )

      assert component_view =~ "Change Username"
      assert component_view =~ "Current password"
      assert component_view =~ "Change username"
    end
  end
end
