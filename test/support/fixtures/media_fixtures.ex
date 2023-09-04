defmodule Livedj.MediaFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Livedj.Media` context.
  """

  @doc """
  Generate a video.
  """
  def video_fixture(attrs \\ %{}) do
    {:ok, video} =
      attrs
      |> Enum.into(%{
        etag: "some etag",
        external_id: "some external_id",
        published_at: ~N[2023-09-02 23:08:00],
        thumbnail_url: "some thumbnail_url",
        title: "some title",
        url: "some url"
      })
      |> Livedj.Media.create_video()

    video
  end
end
