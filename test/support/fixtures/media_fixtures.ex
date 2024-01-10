defmodule Livedj.MediaFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Livedj.Media` context.
  """

  def unique_external_id, do: "some external_id_#{System.unique_integer()}"

  @doc """
  Generate a video.
  """
  def video_fixture(attrs \\ %{}) do
    {:ok, video} =
      attrs
      |> Enum.into(%{
        channel: "some channel",
        etag: "some etag",
        external_id: unique_external_id(),
        published_at: ~N[2023-09-02 23:08:00],
        thumbnail_url: "some thumbnail_url",
        title: "some title"
      })
      |> Livedj.Media.create_video()

    video
  end
end
