defmodule LiveDjWeb.Components.Chat do
  @moduledoc """
  Responsible for chat interactions
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Organizer.Chat

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event(
        "new_message",
        %{"submit" => %{"message" => message}},
        socket
      ) do
    socket = socket |> assign(:new_message, "")

    case String.trim(message) do
      "" ->
        {:noreply, socket}

      _ ->
        %{assigns: assigns} = socket
        %{messages: messages, slug: slug, user: %{username: username}} = assigns
        new_message = %{message: message, username: username}
        message = Chat.create_message(:chat_message, new_message)
        messages = messages ++ [message]

        Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> slug,
          {:receive_messages, %{messages: messages}}
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("typing", _value, %{assigns: assigns} = socket) do
    %{user: %{uuid: uuid}, slug: slug} = assigns
    Chat.start_typing(slug, uuid)
    {:noreply, socket}
  end

  def handle_event("stop_typing", %{"value" => message}, socket) do
    %{assigns: %{user: %{uuid: uuid}, slug: slug}} = socket
    Chat.stop_typing(slug, uuid)
    {:noreply, assign(socket, new_message: message)}
  end

  defp render_prompt(message, assigns) do
    ~H"""
      <span class="use-prompt"><%= message %></span>
    """
  end

  defp render_timestamp(timestamp, assigns) do
    ~H"""
      <span class={"timestamp #{timestamp.class}"}>
        [<%= timestamp.value %>]
      </span>
    """
  end

  defp render_username(username, class, assigns) do
    ~H"""
      <span class={"chat-username #{class}"}><%= username %></span>
    """
  end

  defp render_text(message, class, assigns) do
    ~H"""
      <span class={"chat-text #{class}"}><%= message %></span>
    """
  end

  def render_message({:chat_message, message}, assigns) do
    ~H"""
      <%= render_timestamp(message.timestamp, assigns) %>
      <%= render_prompt(render_username(message.username, "", assigns), assigns) %>
      <%= render_text(message.text, "", assigns) %>
    """
  end

  def render_message({:track_notification, message}, assigns) do
    %{video_title: video_title, added_by: added_by} = message

    video_title = ~H"""
      <span class="highlight-video-title"><%= video_title %></span>
    """

    text = ~H"""
      Playing
      <%= video_title %>,
      added by <span class="font-bold highlight-username"><%= added_by %></span>
    """

    ~H"""
      <%= render_timestamp(message.timestamp, assigns) %>
      <%= render_prompt(render_username(message.username, "highlight-username", assigns), assigns) %>
      <%= render_text(text, "", assigns) %>
    """
  end
end
