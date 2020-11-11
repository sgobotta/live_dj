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
      |> assign(assigns)
    }
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
        Phoenix.PubSub.broadcast_from(
          LiveDj.PubSub,
          self(),
          "room:" <> slug,
          {:receive_messages, %{messages: messages}}
        )
        {:noreply,
          socket
          |> assign(:messages, messages)
          |> push_event("receive_new_message", %{})}
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

  defp render_timestamp(timestamp, username) do
    ~E"""
      <span class="timestamp <%= timestamp.class %>">
        [<%= timestamp.value %>]
        <%= username %>
      </span>
    """
  end

  defp render_username(username) do
    ~E"""
      <b><%= username %>> </b>
    """
  end

  defp render_text(message) do
    ~E"""
      <i><%= message %></i>
    """
  end

  def render_message({:chat_message, message}) do
    ~E"""
      <%= render_timestamp(message.timestamp, render_username(message.username)) %>
      <%= render_text(message.text) %>
    """
  end
end
