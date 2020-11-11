defmodule LiveDj.Organizer.Chat do

  use Phoenix.HTML

  alias LiveDjWeb.Presence

  def create_message(:chat_message, %{message: message, username: username}) do
    {:chat_message,
      %{
        text: message,
        timestamp: create_timestamp(),
        type: :chat_message,
        username: username,
      }
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
