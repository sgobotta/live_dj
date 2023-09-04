defmodule LivedjWeb.Admin.Media.VideoLiveTest do
  @moduledoc false
  use LivedjWeb.ConnCase

  import LivedjWeb.Gettext

  import Phoenix.LiveViewTest
  import Livedj.MediaFixtures

  @create_attrs %{
    etag: "some etag",
    external_id: "some external_id",
    published_at: "2023-09-02T23:08:00",
    thumbnail_url: "some thumbnail_url",
    title: "some title",
    url: "some url"
  }
  @update_attrs %{
    etag: "some updated etag",
    external_id: "some updated external_id",
    published_at: "2023-09-03T23:08:00",
    thumbnail_url: "some updated thumbnail_url",
    title: "some updated title",
    url: "some updated url"
  }
  @invalid_attrs %{
    etag: nil,
    external_id: nil,
    published_at: nil,
    thumbnail_url: nil,
    title: nil,
    url: nil
  }

  defp create_video(_context) do
    video = video_fixture()
    %{video: video}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_video]

    test "lists all videos", %{conn: conn, video: video} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/media/videos")

      assert html =~ "Listing Videos"
      assert html =~ video.etag
    end

    test "saves new video", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/media/videos")

      assert index_live |> element("a", "New Video") |> render_click() =~
               "New Video"

      assert_patch(index_live, ~p"/admin/media/videos/new")

      assert index_live
             |> form("#video-form", video: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can't be blank")

      assert index_live
             |> form("#video-form", video: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/media/videos")

      html = render(index_live)
      assert html =~ gettext("Video created successfully")
      assert html =~ "some etag"
    end

    test "updates video in listing", %{conn: conn, video: video} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/media/videos")

      assert index_live
             |> element("#videos-#{video.id} a", "Edit")
             |> render_click() =~
               gettext("Edit Video")

      assert_patch(index_live, ~p"/admin/media/videos/#{video}/edit")

      assert index_live
             |> form("#video-form", video: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can't be blank")

      assert index_live
             |> form("#video-form", video: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/media/videos")

      html = render(index_live)
      assert html =~ gettext("Video updated successfully")
      assert html =~ "some updated etag"
    end

    test "deletes video in listing", %{conn: conn, video: video} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/media/videos")

      assert index_live
             |> element("#videos-#{video.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#videos-#{video.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_video]

    test "displays video", %{conn: conn, video: video} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/media/videos/#{video}")

      assert html =~ gettext("Show Video")
      assert html =~ video.etag
    end

    test "updates video within modal", %{conn: conn, video: video} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/media/videos/#{video}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               gettext("Edit Video")

      assert_patch(show_live, ~p"/admin/media/videos/#{video}/show/edit")

      assert show_live
             |> form("#video-form", video: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can't be blank")

      assert show_live
             |> form("#video-form", video: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/media/videos/#{video}")

      html = render(show_live)
      assert html =~ gettext("Video updated successfully")
      assert html =~ "some updated etag"
    end
  end
end
