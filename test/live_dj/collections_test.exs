defmodule LiveDj.CollectionsTest do
  use LiveDj.DataCase

  alias LiveDj.Collections

  describe "videos" do
    alias LiveDj.Collections.Video

    @valid_attrs %{channel_title: "some channel_title", description: "some description", img_height: "some img_height", img_url: "some img_url", img_width: "some img_width", title: "some title", video_id: "some video_id"}
    @update_attrs %{channel_title: "some updated channel_title", description: "some updated description", img_height: "some updated img_height", img_url: "some updated img_url", img_width: "some updated img_width", title: "some updated title", video_id: "some updated video_id"}
    @invalid_attrs %{channel_title: nil, description: nil, img_height: nil, img_url: nil, img_width: nil, title: nil, video_id: nil}

    def video_fixture(attrs \\ %{}) do
      {:ok, video} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Collections.create_video()

      video
    end

    test "list_videos/0 returns all videos" do
      video = video_fixture()
      assert Collections.list_videos() == [video]
    end

    test "get_video!/1 returns the video with given id" do
      video = video_fixture()
      assert Collections.get_video!(video.id) == video
    end

    test "create_video/1 with valid data creates a video" do
      assert {:ok, %Video{} = video} = Collections.create_video(@valid_attrs)
      assert video.channel_title == "some channel_title"
      assert video.description == "some description"
      assert video.img_height == "some img_height"
      assert video.img_url == "some img_url"
      assert video.img_width == "some img_width"
      assert video.title == "some title"
      assert video.video_id == "some video_id"
    end

    test "create_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_video(@invalid_attrs)
    end

    test "update_video/2 with valid data updates the video" do
      video = video_fixture()
      assert {:ok, %Video{} = video} = Collections.update_video(video, @update_attrs)
      assert video.channel_title == "some updated channel_title"
      assert video.description == "some updated description"
      assert video.img_height == "some updated img_height"
      assert video.img_url == "some updated img_url"
      assert video.img_width == "some updated img_width"
      assert video.title == "some updated title"
      assert video.video_id == "some updated video_id"
    end

    test "update_video/2 with invalid data returns error changeset" do
      video = video_fixture()
      assert {:error, %Ecto.Changeset{}} = Collections.update_video(video, @invalid_attrs)
      assert video == Collections.get_video!(video.id)
    end

    test "delete_video/1 deletes the video" do
      video = video_fixture()
      assert {:ok, %Video{}} = Collections.delete_video(video)
      assert_raise Ecto.NoResultsError, fn -> Collections.get_video!(video.id) end
    end

    test "change_video/1 returns a video changeset" do
      video = video_fixture()
      assert %Ecto.Changeset{} = Collections.change_video(video)
    end
  end

  describe "users_videos" do
    alias LiveDj.Collections.UserVideo
    alias LiveDj.AccountsFixtures
    alias LiveDj.CollectionsFixtures

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{user_id: nil}

    setup do
      user = AccountsFixtures.user_fixture()
      video = CollectionsFixtures.video_fixture()

      %{user: user, video: video}
    end

    def user_video_fixture(attrs \\ %{}) do
      {:ok, user_video} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Collections.create_user_video()

      user_video
    end

    test "list_users_videos/0 returns all users_videos", %{user: user, video: video} do
      user_video = user_video_fixture(%{user_id: user.id, video_id: video.id})
      assert Collections.list_users_videos() == [user_video]
    end

    test "get_user_video!/1 returns the user_video with given id", %{user: user, video: video} do
      user_video = user_video_fixture(%{user_id: user.id, video_id: video.id})
      assert Collections.get_user_video!(user_video.id) == user_video
    end

    test "create_user_video/1 with valid data creates a user_video", %{user: user, video: video} do
      valid_attrs = Enum.into(@valid_attrs, %{user_id: user.id, video_id: video.id})
      assert {:ok, %UserVideo{} = user_video} = Collections.create_user_video(valid_attrs)
    end

    test "create_user_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_user_video(@invalid_attrs)
    end

    test "update_user_video/2 with valid data updates the user_video", %{user: user, video: video} do
      user_video = user_video_fixture(%{user_id: user.id, video_id: video.id})
      assert {:ok, %UserVideo{} = user_video} = Collections.update_user_video(user_video, @update_attrs)
    end

    test "update_user_video/2 with invalid data returns error changeset", %{user: user, video: video} do
      user_video = user_video_fixture(%{user_id: user.id, video_id: video.id})
      assert {:error, %Ecto.Changeset{}} = Collections.update_user_video(user_video, @invalid_attrs)
      assert user_video == Collections.get_user_video!(user_video.id)
    end

    test "delete_user_video/1 deletes the user_video", %{user: user, video: video} do
      user_video = user_video_fixture(%{user_id: user.id, video_id: video.id})
      assert {:ok, %UserVideo{}} = Collections.delete_user_video(user_video)
      assert_raise Ecto.NoResultsError, fn -> Collections.get_user_video!(user_video.id) end
    end

    test "change_user_video/1 returns a user_video changeset", %{user: user, video: video} do
      user_video = user_video_fixture(%{user_id: user.id, video_id: video.id})
      assert %Ecto.Changeset{} = Collections.change_user_video(user_video)
    end
  end

  describe "playlists" do
    alias LiveDj.Collections.Playlist

    @valid_attrs %{}
    @update_attrs %{}
    # @invalid_attrs %{}

    def playlist_fixture(attrs \\ %{}) do
      {:ok, playlist} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Collections.create_playlist()

      playlist
    end

    test "list_playlists/0 returns all playlists" do
      playlist = playlist_fixture()
      assert Collections.list_playlists() == [playlist]
    end

    test "get_playlist!/1 returns the playlist with given id" do
      playlist = playlist_fixture()
      assert Collections.get_playlist!(playlist.id) == playlist
    end

    test "create_playlist/1 with valid data creates a playlist" do
      assert {:ok, %Playlist{} = playlist} = Collections.create_playlist(@valid_attrs)
    end

    # test "create_playlist/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Collections.create_playlist(@invalid_attrs)
    # end

    test "update_playlist/2 with valid data updates the playlist" do
      playlist = playlist_fixture()
      assert {:ok, %Playlist{} = playlist} = Collections.update_playlist(playlist, @update_attrs)
    end

    # test "update_playlist/2 with invalid data returns error changeset" do
    #   playlist = playlist_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Collections.update_playlist(playlist, @invalid_attrs)
    #   assert playlist == Collections.get_playlist!(playlist.id)
    # end

    test "delete_playlist/1 deletes the playlist" do
      playlist = playlist_fixture()
      assert {:ok, %Playlist{}} = Collections.delete_playlist(playlist)
      assert_raise Ecto.NoResultsError, fn -> Collections.get_playlist!(playlist.id) end
    end

    test "change_playlist/1 returns a playlist changeset" do
      playlist = playlist_fixture()
      assert %Ecto.Changeset{} = Collections.change_playlist(playlist)
    end
  end

  describe "playlists_videos" do
    alias LiveDj.Collections.PlaylistVideo
    alias LiveDj.CollectionsFixtures

    @valid_attrs %{position: 0}
    @update_attrs %{position: 1}
    @invalid_attrs %{}

    setup do
      playlist = CollectionsFixtures.playlist_fixture()
      video = CollectionsFixtures.video_fixture()

      %{playlist: playlist, video: video}
    end

    def playlist_video_fixture(attrs \\ %{}) do
      {:ok, playlist_video} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Collections.create_playlist_video()
      playlist_video
    end

    test "list_playlists_videos/0 returns all playlists_videos",
      %{playlist: playlist, video: video}
    do
      playlist_video_params = %{playlist_id: playlist.id, video_id: video.id}
      playlist_video = playlist_video_fixture(playlist_video_params)
      assert Collections.list_playlists_videos() == [playlist_video]
    end

    test "list_playlists_videos_by_id/0 returns all playlists_videos",
      %{playlist: playlist, video: video}
    do
      playlist_video_params = %{playlist_id: playlist.id, video_id: video.id}
      playlist_video = playlist_video_fixture(playlist_video_params)
      assert Collections.list_playlists_videos_by_id(playlist_video.playlist_id) == [playlist_video]
    end

    test "get_playlist_video!/1 returns the playlist_video with given id",
      %{playlist: playlist, video: video}
    do
      playlist_video_params = %{playlist_id: playlist.id, video_id: video.id}
      playlist_video = playlist_video_fixture(playlist_video_params)
      assert Collections.get_playlist_video!(playlist_video.id) == playlist_video
    end

    test "create_playlist_video/1 with valid data creates a playlist_video",
      %{playlist: playlist, video: video}
    do
      playlist_video_params = %{playlist_id: playlist.id, video_id: video.id}
      valid_attrs = Enum.into(@valid_attrs, playlist_video_params)
      assert {:ok, %PlaylistVideo{} = playlist_video} = Collections.create_playlist_video(valid_attrs)
    end

    test "create_playlist_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_playlist_video(@invalid_attrs)
    end

    test "update_playlist_video/2 with valid data updates the playlist_video",
      %{playlist: playlist, video: video}
    do
      playlist_video_params = %{playlist_id: playlist.id, video_id: video.id}
      playlist_video = playlist_video_fixture(playlist_video_params)
      # Update attrs
      playlist = CollectionsFixtures.playlist_fixture()
      video = Enum.at(CollectionsFixtures.videos, 1)
      video = CollectionsFixtures.video_fixture(video)
      update_attrs = Enum.into(@update_attrs, %{playlist_id: playlist.id, video_id: video.id})
      assert {:ok, %PlaylistVideo{} = playlist_video} = Collections.update_playlist_video(playlist_video, update_attrs)
    end

    test "update_playlist_video/2 with invalid data returns error changeset",
      %{playlist: playlist, video: video}
    do
      playlist_video_params = %{playlist_id: playlist.id, video_id: video.id}
      playlist_video = playlist_video_fixture(playlist_video_params)
      invalid_attrs = Enum.into(@invalid_attrs, %{playlist_id: nil, video_id: nil})
      assert {:error, %Ecto.Changeset{}} = Collections.update_playlist_video(playlist_video, invalid_attrs)
      assert playlist_video == Collections.get_playlist_video!(playlist_video.id)
    end

    test "delete_playlist_video/1 deletes the playlist_video",
      %{playlist: playlist, video: video}
    do
      playlist_video_params = %{playlist_id: playlist.id, video_id: video.id}
      playlist_video = playlist_video_fixture(playlist_video_params)
      assert {:ok, %PlaylistVideo{}} = Collections.delete_playlist_video(playlist_video)
      assert_raise Ecto.NoResultsError, fn -> Collections.get_playlist_video!(playlist_video.id) end
    end

    test "change_playlist_video/1 returns a playlist_video changeset",
      %{playlist: playlist, video: video}
    do
      playlist_video_params = %{playlist_id: playlist.id, video_id: video.id}
      playlist_video = playlist_video_fixture(playlist_video_params)
      assert %Ecto.Changeset{} = Collections.change_playlist_video(playlist_video)
    end
  end
end
