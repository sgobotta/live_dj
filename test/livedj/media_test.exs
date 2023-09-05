defmodule Livedj.MediaTest do
  @moduledoc false
  use Livedj.DataCase

  alias Livedj.Media

  describe "videos" do
    alias Livedj.Media.Video

    import Livedj.MediaFixtures

    @invalid_attrs %{
      etag: nil,
      external_id: nil,
      published_at: nil,
      thumbnail_url: nil,
      title: nil
    }

    test "list_videos/0 returns all videos" do
      video = video_fixture()
      assert Media.list_videos() == [video]
    end

    test "get_video!/1 returns the video with given id" do
      video = video_fixture()
      assert Media.get_video!(video.id) == video
    end

    test "create_video/1 with valid data creates a video" do
      valid_attrs = %{
        etag: "some etag",
        external_id: "some external_id",
        published_at: ~N[2023-09-02 23:08:00],
        thumbnail_url: "some thumbnail_url",
        title: "some title"
      }

      assert {:ok, %Video{} = video} = Media.create_video(valid_attrs)
      assert video.etag == "some etag"
      assert video.external_id == "some external_id"
      assert video.published_at == ~N[2023-09-02 23:08:00]
      assert video.thumbnail_url == "some thumbnail_url"
      assert video.title == "some title"
    end

    test "create_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Media.create_video(@invalid_attrs)
    end

    test "update_video/2 with valid data updates the video" do
      video = video_fixture()

      update_attrs = %{
        etag: "some updated etag",
        external_id: "some updated external_id",
        published_at: ~N[2023-09-03 23:08:00],
        thumbnail_url: "some updated thumbnail_url",
        title: "some updated title"
      }

      assert {:ok, %Video{} = video} = Media.update_video(video, update_attrs)
      assert video.etag == "some updated etag"
      assert video.external_id == "some updated external_id"
      assert video.published_at == ~N[2023-09-03 23:08:00]
      assert video.thumbnail_url == "some updated thumbnail_url"
      assert video.title == "some updated title"
    end

    test "update_video/2 with invalid data returns error changeset" do
      video = video_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Media.update_video(video, @invalid_attrs)

      assert video == Media.get_video!(video.id)
    end

    test "delete_video/1 deletes the video" do
      video = video_fixture()
      assert {:ok, %Video{}} = Media.delete_video(video)
      assert_raise Ecto.NoResultsError, fn -> Media.get_video!(video.id) end
    end

    test "change_video/1 returns a video changeset" do
      video = video_fixture()
      assert %Ecto.Changeset{} = Media.change_video(video)
    end
  end
end
