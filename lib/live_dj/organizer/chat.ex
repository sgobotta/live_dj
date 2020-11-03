defmodule LiveDj.Organizer.Chat do

  use Phoenix.HTML

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
          [<%= timestamp %>] <b><%= uuid %>> </b><i><%= message %></i>
        </p>
      </div>
    """
  end
end
