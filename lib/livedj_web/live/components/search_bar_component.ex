defmodule LivedjWeb.Components.SearchBarComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  alias Livedj.Sessions

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("add_to_playlist", %{"media_id" => media_id}, socket) do
    add_media(socket, media_id)
  end

  def handle_event("change", %{"search" => %{"query" => ""}}, socket) do
    {:noreply, socket}
  end

  def handle_event("change", %{"search" => %{"query" => _search_query}}, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"search" => %{"query" => search_query}}, socket) do
    case validate_url(search_query) do
      {:ok, media_id} ->
        add_media(socket, media_id)

      {:error, :invalid_url} ->
        search_media(socket, search_query)
    end
  end

  def handle_event("submit", _params, socket) do
    {:noreply, socket}
  end

  def open_modal(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#searchbox_container",
      transition:
        {"transition ease-out duration-200", "opacity-0 scale-95",
         "opacity-100 scale-100"}
    )
    |> JS.show(
      to: "#searchbar-dialog",
      transition:
        {"transition ease-in duration-100", "opacity-0", "opacity-100"}
    )
    |> JS.focus(to: "#search-input")
  end

  def hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#searchbar-searchbox_container",
      transition:
        {"transition ease-in duration-300", "opacity-100 scale-100",
         "opacity-0 scale-95"}
    )
    |> JS.hide(
      to: "#searchbar-dialog",
      transition:
        {"transition ease-in duration-300", "opacity-100", "opacity-0"}
    )
  end

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
         |> assign(form: to_form(%{}))
         |> assign(search_form: to_form(%{}))
         |> put_flash(
           :info,
           gettext("%{title} queued to the playlist", title: media.title)
         )}

      {:error, {type, msg}} when type in [:warn, :error] and is_binary(msg) ->
        {:noreply,
         socket
         |> assign(form: to_form(%{}))
         |> put_flash(type, msg)}
    end
  end

  def search_media(socket, query) do
    case Sessions.search_by_query(query) do
      {:ok, result} ->
        {:noreply, assign(socket, search_result: result)}

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
