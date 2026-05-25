defmodule LivedjWeb.Components.SearchBarComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  alias Livedj.Media.Video
  alias Livedj.Sessions
  alias Livedj.Sessions.Channels

  @fake_results (if Mix.env() == :prod do
                   [
                     # ~5 second videos for player edge-case testing
                     %Video{
                       external_id: "QC8iQqtG0hg",
                       title: "5 Second Video: Watch the Milky Way Rise",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/QC8iQqtG0hg/hqdefault.jpg",
                       etag: "fake"
                     },
                     %Video{
                       external_id: "m9coOXt5nuw",
                       title: "5 Second Video Ad (sample 2)",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/m9coOXt5nuw/hqdefault.jpg",
                       etag: "fake"
                     },
                     # 70s rock
                     %Video{
                       external_id: "fJ9rUzIMcZQ",
                       title: "Queen - Bohemian Rhapsody",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg",
                       etag: "fake"
                     },
                     # 70s prog rock
                     %Video{
                       external_id: "_FrOQC-zEog",
                       title: "Pink Floyd - Comfortably Numb",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/_FrOQC-zEog/hqdefault.jpg",
                       etag: "fake"
                     },
                     # 70s rock
                     %Video{
                       external_id: "HQmmM_qwG4k",
                       title: "Led Zeppelin - Whole Lotta Love",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/HQmmM_qwG4k/hqdefault.jpg",
                       etag: "fake"
                     },
                     # 80s rock
                     %Video{
                       external_id: "1w7OgIMMRc4",
                       title: "Guns N' Roses - Sweet Child O' Mine",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/1w7OgIMMRc4/hqdefault.jpg",
                       etag: "fake"
                     },
                     # 80s rock
                     %Video{
                       external_id: "wTP2RUD_cL0",
                       title: "Dire Straits - Money for Nothing",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/wTP2RUD_cL0/hqdefault.jpg",
                       etag: "fake"
                     },
                     # prog rock
                     %Video{
                       external_id: "auLBLk4ibAk",
                       title: "Rush - Tom Sawyer",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/auLBLk4ibAk/hqdefault.jpg",
                       etag: "fake"
                     },
                     # vulfpeck
                     %Video{
                       external_id: "le0BLAEO93g",
                       title: "Vulfpeck - Dean Town",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/le0BLAEO93g/hqdefault.jpg",
                       etag: "fake"
                     },
                     # vulfpeck / cory wong
                     %Video{
                       external_id: "F7nCDrf90V8",
                       title: "VULFPECK /// Disco Ulysses (Instrumental)",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/F7nCDrf90V8/hqdefault.jpg",
                       etag: "fake"
                     },
                     # cory wong
                     %Video{
                       external_id: "HuRaGMyCb2Q",
                       title: "Cory Wong // \"Smooth Move\" (feat. Tom Misch)",
                       thumbnail_url:
                         "https://i.ytimg.com/vi/HuRaGMyCb2Q/hqdefault.jpg",
                       etag: "fake"
                     }
                   ]
                 else
                   []
                 end)

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
      case validate_url(search_query) do
        {:ok, media_id} ->
          add_media(socket, media_id)

        {:error, :invalid_url} ->
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
    stroke-zinc-300 w-10 m-0 h-6 sm:h-7 rounded-md
    flex justify-center items-center border-[1px]
    border-zinc-500 dark:border-zinc-600 opacity-50
    hover:opacity-80 active:opacity-100
    bg-zinc-500 dark:bg-zinc-700 text-zinc-300 dark:text-zinc-200
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

  defp validate_url(url) do
    case URI.parse(url) do
      %URI{query: query} when not is_nil(query) ->
        {:ok, String.replace(query, "v=", "")}

      _uri ->
        {:error, :invalid_url}
    end
  end

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
