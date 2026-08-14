defmodule Livedj.Sessions.ChatServer do
  @moduledoc """
  Per-room GenServer holding the ephemeral chat message list.

  Mutations (send, name update) are applied here and broadcast via PubSub.
  """
  use GenServer, restart: :transient

  alias Livedj.Sessions.{Channels, Chat.Message}

  require Logger

  @send_msg :send_message
  @update_name_msg :update_display_name
  @get_messages_msg :get_messages
  @on_start_cb :on_start

  @cap 200

  @type state :: %{
          id: binary(),
          messages: [Message.t()],
          cap: pos_integer()
        }

  # ----------------------------------------------------------------------------
  # Client interface
  #

  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @spec send_message(
          pid(),
          binary(),
          binary(),
          Message.message_type(),
          binary()
        ) :: :ok
  def send_message(pid, user_id, display_name, type, content) do
    GenServer.cast(pid, {@send_msg, user_id, display_name, type, content})
  end

  @spec update_display_name(pid(), binary(), binary()) :: :ok
  def update_display_name(pid, user_id, new_name) do
    GenServer.cast(pid, {@update_name_msg, user_id, new_name})
  end

  @spec get_messages(pid()) :: [Message.t()]
  def get_messages(pid) do
    GenServer.call(pid, @get_messages_msg)
  end

  @spec initial_state(keyword()) :: state()
  def initial_state(opts) do
    %{
      id: Keyword.fetch!(opts, :id),
      messages: [],
      cap: @cap
    }
  end

  # ----------------------------------------------------------------------------
  # Server implementation
  #

  @impl GenServer
  def init(init_args) do
    Logger.info(
      "#{__MODULE__} :: Started process pid=#{inspect(self())}, args=#{inspect(init_args)}"
    )

    {:ok, initial_state(init_args),
     {:continue, {@on_start_cb, Keyword.fetch!(init_args, :on_start)}}}
  end

  @impl GenServer
  def handle_continue({@on_start_cb, on_start}, state) do
    :ok = on_start.(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(@get_messages_msg, _from, state) do
    {:reply, state.messages, state}
  end

  @impl GenServer
  def handle_cast({@send_msg, user_id, display_name, type, content}, state) do
    message = Message.new(state.id, user_id, display_name, type, content)
    messages = trim([message | state.messages], state.cap)
    :ok = Channels.broadcast_message_sent!(state.id, message)
    {:noreply, %{state | messages: messages}}
  end

  def handle_cast({@update_name_msg, user_id, new_name}, state) do
    messages =
      Enum.map(state.messages, fn
        %Message{user_id: ^user_id} = msg -> %{msg | display_name: new_name}
        msg -> msg
      end)

    :ok = Channels.broadcast_messages_updated!(state.id, messages)
    :ok = Channels.broadcast_display_name_changed!(state.id, user_id, new_name)
    {:noreply, %{state | messages: messages}}
  end

  @spec trim([Message.t()], pos_integer()) :: [Message.t()]
  defp trim(messages, cap) when length(messages) > cap,
    do: Enum.take(messages, cap)

  defp trim(messages, _cap), do: messages
end
