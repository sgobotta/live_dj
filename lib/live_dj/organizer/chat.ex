defmodule LiveDj.Organizer.Chat do

  use Phoenix.HTML

  alias LiveDjWeb.Presence

  def render_timestamp(timestamp, username) do
    ~E"""
      <span class="timestamp <%= timestamp.class %>">
        [<%= timestamp.value %>]
        <%= username %>
      </span>
    """
  end

  def render_username(username) do
    ~E"""
      <b><%= username %>> </b>
    """
  end

  def render_message(message) do
    ~E"""
      <i><%= message %></i>
    """
  end

  def create_message(:presence_joins, %{uuid: uuid}) do
    ~E"""
      <div class="chat-presence">
        <p class="chat-message"><b><%= uuid %></b> has connected</p>
      </div>
    """
  end

  def create_message(:presence_leaves, %{uuid: uuid}) do
    ~E"""
      <div class="chat-presence">
        <p class="chat-message"><b><%= uuid %></b> has disconnected</p>
      </div>
    """
  end

  def create_message(:new, %{message: message, username: username}) do
    %{
      text: message,
      timestamp: create_timestamp(),
      username: username
    }
  end

  def start_typing(slug, uuid) do
    topic = "room:" <> slug
    key = uuid
    payload = %{typing: true}
    update_presence_state(topic, key, payload)
  end

  def stop_typing(slug, uuid) do
    topic = "room:" <> slug
    key = uuid
    payload = %{typing: false}
    update_presence_state(topic, key, payload)
  end

  defp update_presence_state(topic, key, payload) do
    metas =
      Presence.get_by_key(topic, key)[:metas]
      |> hd
      |> Map.merge(payload)

    Presence.update(self(), topic, key, metas)
  end

  defp create_timestamp do
    timestamp = DateTime.now(System.get_env("TZ"), Tzdata.TimeZoneDatabase)
    |> elem(1)
    |> Time.to_string()
    |> String.split(".")
    |> hd
    highlight_style =
      case timestamp =~ "04:20:" || timestamp =~ "16:20:" do
        true -> "highlight-timestamp"
        false -> "timestamp-message"
      end
    %{
      value: timestamp,
      class: highlight_style
    }
  end
end
