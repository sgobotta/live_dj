# Room Chat Design

**Date:** 2026-05-30
**Status:** Approved

## Overview

A real-time, ephemeral chat system for LiveDJ rooms. Users (authenticated and guests) can send messages and slash commands from a panel below the player. Messages are broadcast to all peers in the room via PubSub. A `ChatServer` GenServer per room is the single source of truth for message state, enabling retroactive mutations (e.g. name changes) and centralized command dispatch.

## Requirements

- All users (registered and guests) can send messages
- Messages are ephemeral — stored in the `ChatServer` process, lost if the room ends or the server restarts
- Late joiners receive the current message list on mount (up to 200 messages)
- Retroactive display name updates: when a user changes their name, all their previous messages update and peers see the refresh immediately
- Slash commands (`/skip`, `/queue`, `/name`, `/me`, `/msg`, etc.) are parsed and dispatched to the appropriate server
- Command system is extensible — new commands require only a parser clause and a dispatcher route
- Cross-room messaging is supported via `/msg <room_id> <content>`
- Chat panel is toggled via a header button and the `Y` keybinding
- Chat panel is visible by default

## Data Model

```elixir
defmodule Livedj.Sessions.Chat.Message do
  @type t :: %__MODULE__{
    id:           binary(),   # UUID, stable identifier
    room_id:      binary(),   # origin room — enables cross-room message display
    user_id:      binary(),   # User.id or Guest.id
    display_name: binary(),   # cached at send time, mutable via ChatServer
    type:         :text | :system | :reaction | :command_result,
    content:      binary(),
    inserted_at:  DateTime.t()
  }
end
```

`display_name` is cached on the message (not resolved from Presence at render time) so the `ChatServer` can update it in one place and broadcast a single refresh to all peers.

`room_id` is the origin room, allowing the target room's UI to display cross-room messages with their source.

## Architecture

### `ChatServer` — `Livedj.Sessions.ChatServer`

A supervised GenServer per room, following the same pattern as `PlayerServer` and `PlaylistServer`.

**State:**

```elixir
defstruct [
  room_id:  nil,
  messages: [],   # newest first
  cap:      200
]
```

**Public API:**

```elixir
# Called by the command dispatcher on text or reaction input
ChatServer.send_message(room_id, user_id, display_name, type, content)

# Called when a user changes their display name
ChatServer.update_display_name(room_id, user_id, new_name)

# Called by the LiveView on mount to populate initial state
ChatServer.get_messages(room_id)
```

**Internals:**

- `send_message` creates a `Message` struct, prepends to the list, trims to cap, broadcasts `message_sent` via PubSub
- `update_display_name` walks the list and updates all messages matching `user_id`, then broadcasts `messages_updated` with the full list
- The cap is 200 messages; oldest entries are dropped when exceeded

### Supervision

```
Sessions.Supervisor
  ├── PlayerSupervisor
  │     └── PlayerServer (per room)
  ├── PlaylistSupervisor
  │     └── PlaylistServer (per room)
  └── ChatSupervisor        ← new
        └── ChatServer (per room)
```

`ChatServer` shares the room lifecycle — started when a room is created, stopped when the room ends.

## Command System

### Parser — `Livedj.Sessions.Chat.Commands.Parser`

Parses raw input into a tagged tuple before anything reaches a server.

```elixir
"/skip"           → {:ok, {:skip, []}}
"/queue <url>"    → {:ok, {:queue, [url]}}
"/name <new>"     → {:ok, {:name, [new_name]}}
"/me <text>"      → {:ok, {:me, [text]}}
"/msg <room> ..." → {:ok, {:msg, [room_id, content]}}
"hello world"     → {:ok, {:text, ["hello world"]}}
"/unknown"        → {:error, :unknown_command}
```

Plain text always passes through as `{:text, [content]}`.

### Dispatcher — `Livedj.Sessions.Chat.Commands.Dispatcher`

Routes parsed commands to the appropriate server:

| Command | Routes to |
|---|---|
| `:text` | `ChatServer.send_message/5` with `type: :text` |
| `:me` | `ChatServer.send_message/5` with `type: :reaction` |
| `:skip` | `PlayerServer` |
| `:queue` | `PlaylistServer` |
| `:name` | `Accounts` / `Presence`, then `ChatServer.update_display_name/3` |
| `:msg` | target room's `ChatServer` via Registry lookup |
| `:unknown_command` | `ChatServer.send_message/5` with `type: :system`, content `"Unknown command: /foo"` |

**Extension pattern:** adding a new command = one parse clause in `Parser` + one route in `Dispatcher`. Neither `ChatServer` nor the LiveView changes.

## Channels + PubSub

New additions to `Livedj.Sessions.Channels`, following the existing topic/event pattern:

**Topic:**
```elixir
def chat_topic(room_id), do: "chat:" <> room_id
```

**Events:**
```elixir
:message_sent      # single new message arrived
:messages_updated  # full list refresh (e.g. after name change)
```

**Broadcasts (called by `ChatServer`):**
```elixir
def broadcast_message_sent!(room_id, %Message{} = message)
def broadcast_messages_updated!(room_id, messages)
```

**LiveView handlers in `Show`:**
```elixir
def handle_info({:message_sent, _room_id, message}, socket) do
  {:noreply, update(socket, :messages, &[message | &1])}
end

def handle_info({:messages_updated, _room_id, messages}, socket) do
  {:noreply, assign(socket, :messages, messages)}
end
```

`message_sent` prepends one message efficiently. `messages_updated` replaces the full list and is only triggered on bulk mutations — infrequent by design.

## UI

### Chat Panel (`show.html.heex`)

Replaces the existing `#chat-container` stub. Rendered conditionally on `@chat_visible`.

```
┌─────────────────────────────┐
│ Messages list (scrollable)  │
│                             │
│ [user] hello world     12:01│
│ * user dances          12:02│  ← :reaction, italicised
│ ★ track skipped        12:03│  ← :system/:command_result, muted
│                             │
├─────────────────────────────┤
│ > type a message...   [Send]│
└─────────────────────────────┘
```

Message rendering by type:
- `:text` — `[display_name] content`
- `:reaction` — `* display_name content`, italicised
- `:system` / `:command_result` — muted, no username

Form submit triggers `send_message` event in `Show`, which calls `Dispatcher.dispatch/3`. Enter key submits via a JS hook.

### Header Toggle Button (`session.html.heex`)

Added left of the Share button, following the same icon + tooltip structure as Help and Share:

- Icon: `hero-chat-bubble-left-ellipsis`
- Tooltip: `"Chat (Y)"`
- `phx-click="toggle_chat"` on `Show`

Button order (right side of header): `[?] [💬] [↗] [avatar]`

### Y Keybinding

One new entry in the existing keybindings system. Pushes `toggle_chat` to the `Show` LiveView, same pattern as `T` → toggle theme.

**`Show` handler:**
```elixir
def handle_event("toggle_chat", _, socket) do
  {:noreply, update(socket, :chat_visible, &(!&1))}
end
```

`@chat_visible` defaults to `true` on mount.

## Files Affected

| File | Change |
|---|---|
| `lib/livedj/sessions/chat/message.ex` | new — Message struct |
| `lib/livedj/sessions/chat_server.ex` | new — GenServer |
| `lib/livedj/sessions/chat_supervisor.ex` | new — Supervisor |
| `lib/livedj/sessions/chat/commands/parser.ex` | new — command parser |
| `lib/livedj/sessions/chat/commands/dispatcher.ex` | new — command dispatcher |
| `lib/livedj/sessions/channels.ex` | add chat topic, events, broadcasts |
| `lib/livedj/sessions/supervisor.ex` | add ChatSupervisor as child |
| `lib/livedj_web/live/sessions/room_live/show.ex` | subscribe, handle_info, handle_event, assigns |
| `lib/livedj_web/live/sessions/room_live/show.html.heex` | replace chat-container stub |
| `lib/livedj_web/components/layouts/session.html.heex` | add chat toggle button |
| `assets/js/keybindings.js` | add Y keybinding |
