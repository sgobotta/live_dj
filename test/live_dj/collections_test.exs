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
end
