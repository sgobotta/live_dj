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
end
