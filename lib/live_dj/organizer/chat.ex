defmodule LiveDj.Organizer.Chat do

  use Phoenix.HTML

  alias LiveDjWeb.Presence

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

  def create_message(:new, %{message: message, uuid: uuid}) do
    timestamp = Time.to_string(NaiveDateTime.local_now())
    ~E"""
      <div>
        <p class="chat-message">
          <span class="timestamp">
            [<%= timestamp %>]
            <b><%= uuid %>> </b>
          </span>
          <i><%= message %></i>
        </p>
      </div>
    """
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
end
