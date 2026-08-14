defmodule LivedjWeb.Components.SearchBarComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  alias Livedj.Media
  alias Livedj.Media.FakeVideos
  alias Livedj.Media.Video
  alias Livedj.Sessions
  alias Livedj.Sessions.Channels

  @fake_results if Mix.env() == :dev, do: FakeVideos.results(), else: []

  @impl true
  def update(%{track_added: %Video{external_id: external_id}}, socket) do
    {:ok, update(socket, :playlist_external_ids, &MapSet.put(&1, external_id))}
  end

  def update(%{track_removed: external_id}, socket) do
    {:ok,
     update(socket, :playlist_external_ids, &MapSet.delete(&1, external_id))}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, &empty_search_form/0)
     |> assign_new(:search_result, fn -> @fake_results end)
     |> assign_new(:playlist_external_ids, fn %{room: room} ->
       case Sessions.get_playlist(room.id) do
         {:ok, list} -> MapSet.new(list, & &1.external_id)
         {:error, _error} -> MapSet.new()
       end
     end)
     |> assign_new(:playlist_subscribed, fn %{room: room} ->
       Channels.subscribe_playlist_topic(room.id)
     end)}
  end

  @impl true
  def handle_event("add_to_playlist", %{"media_id" => media_id}, socket) do
    add_media(socket, media_id)
  end

  def handle_event("change", %{"search" => %{"query" => query}}, socket) do
    {:noreply, assign(socket, form: search_form(query))}
  end

  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"search" => %{"query" => search_query}}, socket) do
    if query_present?(search_query) do
      media_id = Media.video_id_from_url(search_query)

      if media_id != search_query do
        add_media(socket, media_id)
      else
        search_media(socket, search_query)
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("submit", _params, socket) do
    {:noreply, socket}
  end

  def search_submit_enabled?(form) do
    query_present?(form[:query].value)
  end

  def search_kbd_class do
    """
    stroke-tone-300 w-10 m-0 h-6 sm:h-7 rounded-md
    flex justify-center items-center border-[1px]
    border-tone-500 dark:border-tone-600 opacity-50
    hover:opacity-80 active:opacity-100
    bg-tone-500 dark:bg-tone-700 text-tone-300 dark:text-tone-200
    text-xs md:text-sm font-medium cursor-pointer
    shadow-[2.0px_2.0px_1px_0.5px_rgba(24,24,27,0.5)]
    hover:shadow-[1.5px_1.5px_1px_0.5px_rgba(24,24,27,0.9)]
    active:shadow-[0.5px_0.5px_1px_0.5px_rgba(24,24,27,0.2)]
    dark:shadow-[1.5px_1.5px_1px_0.5px_rgba(250,250,255,0.4)]
    dark:hover:shadow-[1.5px_1.5px_1px_0.5px_rgba(250,250,255,0.6)]
    dark:active:shadow-[0.5px_0.5px_1px_0.5px_rgba(250,250,255,0.2)]
    """
  end

  defp query_present?(query) do
    query |> to_string() |> String.trim() != ""
  end

  defp empty_search_form, do: search_form("")

  defp search_form(query), do: to_form(%{"query" => query}, as: :search)

  defp add_media(socket, media_id) do
    case Sessions.add_media(socket.assigns.room.id, media_id) do
      {:ok, {:added, media}} ->
        {:noreply,
         socket
         |> update(:playlist_external_ids, &MapSet.put(&1, media_id))
         |> put_flash(
           :info,
           gettext("%{title} queued to the playlist", title: media.title)
         )}

      {:error, {type, msg}} when type in [:warn, :error] and is_binary(msg) ->
        {:noreply, put_flash(socket, type, msg)}
    end
  end

  def search_media(socket, query) do
    case Sessions.search_by_query(query) do
      {:ok, result} ->
        {:noreply,
         socket
         |> assign(search_result: result)
         |> assign(form: search_form(query))}

      {:error, :service_unavailable} ->
        {:noreply,
         socket
         |> put_flash(
           :warn,
           dgettext(
             "warnings",
             "Search service unavailable. Please try inserting a youtube url."
           )
         )}
    end
  end
end
