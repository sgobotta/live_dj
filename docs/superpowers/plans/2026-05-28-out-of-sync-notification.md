# Out-of-Sync Notification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a user seeks to a position more than 5 seconds away from the room's synchronized playback time, show a non-blocking banner with a "Resync" button that snaps them back to the room's current time.

**Architecture:** On slider commit (`change` event), the JS hook pushes `seek_committed` with the user's chosen time to `RoomLive.Show`. The server computes the delta against the authoritative room time (already computed by `PlaybackPosition.sync` inside `Sessions.get_player/1`), and if it exceeds the threshold pushes `player_out_of_sync` back to the client only. The JS hook shows a pre-rendered banner inside `#video-player-hook`. Clicking "Resync" pushes `on_player_resync` to the server, which replies with the standard `set_current_time` event (already handled by the hook) to snap the player back, and the hook hides the banner.

**Tech Stack:** Elixir/Phoenix LiveView, Phoenix.PubSub, YouTube IFrame API (JS), Tailwind CSS v4.

---

## File Map

| File | Change |
|---|---|
| `assets/js/youtube/hook.js` | Push `seek_committed`; handle `player_out_of_sync`; hide banner on `set_current_time` + `load_video`; set up resync/dismiss listeners |
| `lib/livedj_web/components/layouts/root_session.html.heex` | Add hidden banner div inside `#video-player-hook` |
| `lib/livedj_web/live/sessions/room_live/show.ex` | Handle `seek_committed` (compute delta, push event); handle `on_player_resync` (push `set_current_time`) |

---

## Task 1: Push `seek_committed` from JS and handle it on the server

**Files:**
- Modify: `assets/js/youtube/hook.js` — `_onSliderCommit` handler
- Modify: `lib/livedj_web/live/sessions/room_live/show.ex` — add two `handle_event` clauses

### Understanding the current flow

`_onSliderCommit` is a document-level delegated handler (set up in `mounted()`):

```javascript
this._onSliderCommit = (e) => {
  if (e.target.id !== this.timeSliderId) return
  this._isPeeking = false
  if (this.player) this.player.seekTo(parseFloat(e.target.value), true)
}
```

`pushEventTo(this.el, eventName, payload)` sends from the hook element to `RoomLive.Show` (the LiveView that owns `#video-player-hook`).

`Sessions.get_player/1` already returns a synced player struct — it calls `PlaybackPosition.sync/1` internally, which adds elapsed seconds to `current_time` when state is `:playing`.

### Out-of-sync threshold

```elixir
@out_of_sync_threshold_seconds 5
```

Delta = `abs(room_current_time - committed_time)`. Direction: when `committed_time > room_time`, the user is `:ahead`; when `committed_time < room_time`, they are `:behind`.

- [ ] **Step 1: Update `_onSliderCommit` to push `seek_committed`**

In `assets/js/youtube/hook.js`, replace the `_onSliderCommit` assignment in `mounted()`:

```javascript
// Before:
this._onSliderCommit = (e) => {
  if (e.target.id !== this.timeSliderId) return
  this._isPeeking = false
  if (this.player) this.player.seekTo(parseFloat(e.target.value), true)
}

// After:
this._onSliderCommit = async (e) => {
  if (e.target.id !== this.timeSliderId) return
  this._isPeeking = false
  if (!this.player) return
  const committedTime = parseFloat(e.target.value)
  this.player.seekTo(committedTime, true)
  await this.pushEventTo(this.el, 'seek_committed', {
    committed_time: committedTime
  })
}
```

- [ ] **Step 2: Add `seek_committed` and `on_player_resync` handlers in `show.ex`**

In `lib/livedj_web/live/sessions/room_live/show.ex`, add after the existing `handle_event("on_player_visible", ...)` clause (around line 156):

```elixir
@out_of_sync_threshold_seconds 5

def handle_event(
      "seek_committed",
      %{"committed_time" => committed_time},
      socket
    ) do
  room_id = socket.assigns.room.id

  case Sessions.get_player(room_id) do
    {:ok, %Sessions.Player{state: state, current_time: room_time}}
    when state in [:playing, :paused] ->
      delta = abs(trunc(room_time) - trunc(committed_time))

      if delta > @out_of_sync_threshold_seconds do
        direction =
          if committed_time > room_time, do: "ahead", else: "behind"

        {:noreply,
         push_event(socket, "player_out_of_sync", %{
           delta: delta,
           direction: direction
         })}
      else
        {:noreply, socket}
      end

    _other ->
      {:noreply, socket}
  end
end

def handle_event("on_player_resync", _params, socket) do
  case Sessions.get_player(socket.assigns.room.id) do
    {:ok, %Sessions.Player{current_time: room_time}} ->
      {:noreply,
       push_event(socket, "set_current_time", %{current_time: room_time})}

    _error ->
      {:noreply, socket}
  end
end
```

- [ ] **Step 3: Verify the server compiles**

```bash
cd /path/to/live_dj && mix compile --warnings-as-errors 2>&1
```

Expected: no errors, no warnings related to the new clauses.

- [ ] **Step 4: Commit**

```bash
git add assets/js/youtube/hook.js \
        lib/livedj_web/live/sessions/room_live/show.ex
git commit -m "feat: push seek_committed event and handle out-of-sync detection on server"
```

---

## Task 2: Add the notification banner UI

**Files:**
- Modify: `lib/livedj_web/components/layouts/root_session.html.heex`

The banner lives **inside** `#video-player-hook` (which is `phx-update="ignore"`), so LiveView will never touch it after the initial render. The JS hook controls its visibility directly via DOM.

Position it absolutely at the bottom of the player area, above the player (z-20).

- [ ] **Step 1: Add banner div inside `#video-player-hook`**

In `lib/livedj_web/components/layouts/root_session.html.heex`, add the banner as the last child inside the outer `<div id="video-player-hook" ...>`, after the `#player-backdrop` div:

```heex
<div
  id="video-player-hook"
  phx-hook="Youtube"
  phx-update="ignore"
  class="mx-1 w-[98%] h-72 relative flex my-2"
>
  <div class="w-full">
    <div
      id="player-container"
      class="w-full h-72 rounded-lg transition duration-1000 hidden mr-1"
    />
  </div>
  <div
    id="player-backdrop"
    phx-hook="PlayerBackdrop"
    class="absolute w-full h-full bg-black rounded-lg overflow-hidden"
  >
    <canvas
      id="player-spinner"
      class="hidden absolute inset-0 w-full h-full rounded-lg"
    />
  </div>

  <%!-- Out-of-sync notification banner --%>
  <div
    id="out-of-sync-banner"
    class="absolute bottom-2 left-0 right-0 mx-2 hidden z-20"
  >
    <div class="
      flex items-center justify-between gap-2
      bg-amber-900/90 text-amber-100
      rounded-lg px-3 py-2 text-sm shadow-lg
    ">
      <span id="out-of-sync-message"></span>
      <div class="flex items-center gap-2 shrink-0">
        <button
          id="resync-btn"
          class="font-semibold underline underline-offset-2 hover:text-white"
        >
          Resync
        </button>
        <button
          id="out-of-sync-dismiss"
          class="text-lg leading-none opacity-70 hover:opacity-100"
          aria-label="Dismiss"
        >
          ×
        </button>
      </div>
    </div>
  </div>
</div>
```

- [ ] **Step 2: Verify the page renders without error**

Load the app in the browser and navigate to a room. The banner should not be visible (it has `hidden`). Check browser console for errors.

- [ ] **Step 3: Commit**

```bash
git add lib/livedj_web/components/layouts/root_session.html.heex
git commit -m "feat: add hidden out-of-sync notification banner to player"
```

---

## Task 3: Wire the banner to JS hook events

**Files:**
- Modify: `assets/js/youtube/hook.js`

Add two helper methods on the hook object: `_showOutOfSyncBanner` and `_hideOutOfSyncBanner`. Call `_showOutOfSyncBanner` from a new `player_out_of_sync` event handler. Call `_hideOutOfSyncBanner` inside the existing `set_current_time` and `load_video` event handlers.

- [ ] **Step 1: Add `player_out_of_sync` event handler in `mounted()`**

In `assets/js/youtube/hook.js`, add inside `mounted()` after the existing `handleEvent('fullscreen', ...)` block (near line 390 — the last `handleEvent` before the closing `},` of `mounted`):

```javascript
/**
 * player_out_of_sync
 *
 * Received when the user's committed seek position differs from the room's
 * authoritative playback time by more than the server threshold.
 */
this.handleEvent('player_out_of_sync', ({ delta, direction }) => {
  const dir = direction === 'ahead' ? 'ahead of' : 'behind'
  const message = document.getElementById('out-of-sync-message')
  if (message) message.textContent = `You're ${delta}s ${dir} the room.`
  this._showOutOfSyncBanner()
})
```

- [ ] **Step 2: Hide banner when `set_current_time` fires**

In the existing `set_current_time` handler in `mounted()`:

```javascript
// Before:
this.handleEvent('set_current_time', async ({
  current_time: currentTime
}) => {
  console.debug('[Player :: set_current_time]')
  this.player.seekTo(currentTime, true)
})

// After:
this.handleEvent('set_current_time', async ({
  current_time: currentTime
}) => {
  console.debug('[Player :: set_current_time]')
  this.player.seekTo(currentTime, true)
  this._hideOutOfSyncBanner()
})
```

- [ ] **Step 3: Hide banner when a new video loads**

In the existing `load_video` handler in `mounted()`, add `this._hideOutOfSyncBanner()` at the start of the handler body:

```javascript
this.handleEvent('load_video', async (player) => {
  console.debug('[Player :: load_video]', player)
  console.debug('[Player :: load_video state]', player.state)
  this._hideOutOfSyncBanner()  // ← add this line
  switch (player.state) {
    // ... existing cases unchanged
  }
  scrollToElement(`${player.media_id}-item`)
})
```

- [ ] **Step 4: Add `_showOutOfSyncBanner` and `_hideOutOfSyncBanner` as hook object methods**

At the bottom of the exported hook object (alongside `positionPlayer`, `spinnerId`, etc.), add:

```javascript
_showOutOfSyncBanner() {
  const banner = document.getElementById('out-of-sync-banner')
  if (banner) banner.classList.remove('hidden')
},
_hideOutOfSyncBanner() {
  const banner = document.getElementById('out-of-sync-banner')
  if (banner) banner.classList.add('hidden')
},
```

The ESLint rule requires object keys in ascending order. `_hideOutOfSyncBanner` and `_showOutOfSyncBanner` both start with `_` so they come before `backdrop_id` alphabetically. Place them after `_isPeeking` at the top of the export object:

```javascript
export default {
  _hideOutOfSyncBanner() {
    const banner = document.getElementById('out-of-sync-banner')
    if (banner) banner.classList.add('hidden')
  },
  _isPeeking: false,
  _showOutOfSyncBanner() {
    const banner = document.getElementById('out-of-sync-banner')
    if (banner) banner.classList.remove('hidden')
  },
  backdrop_id: null,
  // ... rest unchanged
```

(Remove the duplicate definitions from the bottom of the object if you added them there.)

- [ ] **Step 5: Run ESLint**

```bash
cd assets && npx eslint js/youtube/hook.js
```

Expected: no output (clean).

- [ ] **Step 6: Commit**

```bash
git add assets/js/youtube/hook.js
git commit -m "feat: show/hide out-of-sync banner from YouTube hook events"
```

---

## Task 4: Resync and dismiss button listeners

**Files:**
- Modify: `assets/js/youtube/hook.js` — add button listeners in `mounted()`

The "Resync" button pushes `on_player_resync` to the server, which replies with `set_current_time`. The `set_current_time` handler (updated in Task 3) already hides the banner and calls `seekTo`. The "×" dismiss button simply hides the banner client-side.

- [ ] **Step 1: Add button listeners in `mounted()`**

In `assets/js/youtube/hook.js`, after the existing `window.addEventListener('resize', this._onResize)` line and before the slider listeners, add:

```javascript
this._onResyncClick = async () => {
  await this.pushEventTo(this.el, 'on_player_resync')
}
this._onDismissClick = () => {
  this._hideOutOfSyncBanner()
}

document.getElementById('resync-btn')
  ?.addEventListener('click', this._onResyncClick)
document.getElementById('out-of-sync-dismiss')
  ?.addEventListener('click', this._onDismissClick)
```

- [ ] **Step 2: Clean up listeners in `destroyed()`**

Add removals to the existing `destroyed()` method:

```javascript
destroyed() {
  window.removeEventListener('resize', this._onResize)
  document.removeEventListener('mousedown', this._onSliderMousedown)
  document.removeEventListener('touchstart', this._onSliderTouchstart)
  document.removeEventListener('input', this._onSliderInput)
  document.removeEventListener('change', this._onSliderCommit)
  document.removeEventListener('mouseup', this._onDocMouseup)
  document.getElementById('resync-btn')
    ?.removeEventListener('click', this._onResyncClick)
  document.getElementById('out-of-sync-dismiss')
    ?.removeEventListener('click', this._onDismissClick)
},
```

- [ ] **Step 3: Run ESLint**

```bash
cd assets && npx eslint js/youtube/hook.js
```

Expected: no output.

- [ ] **Step 4: Manual smoke test**

1. Open a room with a song playing.
2. Drag the seek bar forward by a large amount (> 5 seconds), then release.
3. Expect: banner appears — "You're Xs ahead of the room."
4. Click "Resync" → banner disappears, video snaps to room time.
5. Seek forward again, then click "×" → banner disappears, video stays where you seeked.
6. Seek backward by a large amount → banner appears with "behind" message.
7. Skip to next track → banner disappears automatically.

- [ ] **Step 5: Commit**

```bash
git add assets/js/youtube/hook.js
git commit -m "feat: wire resync and dismiss buttons for out-of-sync banner"
```

---

## Self-Review

**Spec coverage:**
- ✅ User moves seek bar forward/backward → out of sync detected
- ✅ Server is authoritative source of room time (via `Sessions.get_player/1` → `PlaybackPosition.sync`)
- ✅ Threshold: 5 seconds
- ✅ Banner shows direction (ahead / behind) and delta in seconds
- ✅ "Resync" snaps back to room time
- ✅ "×" dismisses without seeking
- ✅ Banner auto-hides on new track load
- ✅ Banner auto-hides on resync (`set_current_time` handler)
- ✅ No notification during pure preview dragging (banner only shown on commit)

**Placeholder scan:** None found.

**Type consistency:**
- `committed_time` is the JS float passed as `seek_committed` payload; received in Elixir as `%{"committed_time" => committed_time}` — consistent.
- `room_time` comes from `Sessions.Player.t().current_time` which is `non_neg_integer()` after `PlaybackPosition.sync`. The `trunc/1` call handles the float-to-integer coercion.
- `player_out_of_sync` payload keys (`delta`, `direction`) are consistent between the `push_event` call and the JS `handleEvent` destructuring.
- `_showOutOfSyncBanner` / `_hideOutOfSyncBanner` names are consistent across all references.
