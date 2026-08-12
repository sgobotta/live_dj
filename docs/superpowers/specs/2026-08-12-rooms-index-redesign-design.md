# Rooms Index Redesign — Design Spec

**Date:** 2026-08-12
**Status:** Approved (design), pending implementation plan
**Scope:** Visual + layout redesign of the public rooms listing page (`LivedjWeb.Sessions.RoomLive.Index`).

---

## Goal

Modernize the public rooms listing page. Move from the current cramped single-row horizontal
scroller of small tiles to an editorial "discovery" layout: a **featured (hero) room** at the top
followed by a **responsive grid** of the remaining rooms. Give it a modern music-app feel (à la
Spotify / Apple Music) while staying strictly within the existing design system — the swappable
`tone-*` neutral palette and the `brand` (violet) accent — and remaining fully light/dark and
tone-swap aware.

This is a **visual + layout** change. It surfaces one new piece of information per room
(now-playing track title) using data that already exists. No new persisted data, no schema
changes.

## Non-goals

- No search / filter / sort controls.
- No listener-count text or "LIVE" badge, no playlist-length indicator.
- No changes to room creation, room navigation, auth, or presence/player backends.
- No changes to the in-room experience (`show`, playlist `list`, player).

---

## Current state (baseline)

- **LiveView:** `lib/livedj_web/live/sessions/room_live/index.ex` — on connect, loads
  `Sessions.list_rooms()`, joins each room's player, subscribes to each room's presence topic, and
  builds `@rooms_players` as a list of
  `%{id, room: %Room{}, player: %Player{} | nil, users: [presence...]}`. Player and presence
  updates flow in via `handle_info` and patch individual entries in `@rooms_players`.
- **Template:** `lib/livedj_web/live/sessions/room_live/index.html.heex` — a horizontally
  scrolling `<.room_grid>` of `w-40 h-52` cards. Each card renders a `LivedjWeb.PlayerPreview`
  live component (cover art / musical-note placeholder + lock badge), the room name, and a
  `<.mini_avatar_stack>`. A fixed "New Room" FAB and a create-room modal sit below.
- **`room_grid`** (`lib/livedj_web/components/custom_components.ex`) — renders
  `grid-flow-col auto-cols-max` (single horizontal row) of fixed-size card shells.
- **`PlayerPreview`** (`lib/livedj_web/components/player_preview.ex`) — 160×160 cover art or
  musical-note placeholder; lock badge overlay when `Sessions.room_protected?(@room)`; pulse
  animation when paused.

### Data available (no backend work needed)

- `Player` struct carries `:title` (track title) and `:channel` (artist/uploader) in addition to
  `:media_thumbnail_url` and `:state` (`:idle | :playing | :paused`). So "now-playing title" is
  already in hand.
- `users` (presence list) per room is already tracked → "most active" ranking is free.

### Theming constraints (must honor)

- Tailwind v4 with `@theme` tokens in `assets/css/app.css`. Neutrals come from `tone-50…tone-950`,
  which map to a swappable base (`data-tone` → zinc default / slate / gray / stone). Accent is
  `--color-brand: violet`.
- Dark mode is the `.dark` class variant (`@variant dark`).
- **Rule:** style only with `tone-*` and `brand` tokens (+ standard Tailwind utilities). Never
  hard-code neutral colors like `bg-gray-800` where a `tone-*` token exists, so theme + tone
  swapping keeps working. (Note: `PlayerPreview`'s placeholder currently uses `bg-gray-200
  dark:bg-gray-800` / `text-zinc-500` — migrate these to `tone-*` as part of this work.)

---

## Target design

### 1. Page structure (`index.html.heex`)

Rendered inside the existing `connected?/1` guard. Top to bottom:

1. **Header** — `<.header>` "Public rooms", with more vertical breathing room than today.
2. **Featured hero** — the single most-active room (see ranking below), rendered large and
   full-width. Absent only when there are zero rooms.
3. **"More rooms" grid** — all rooms except the featured one, in a responsive wrapping grid.
   When there is exactly one room total, the grid is omitted (only the hero shows).
4. **Empty state** — when there are **no** rooms at all, replace hero + grid with a friendly
   centered message and a primary "New Room" call-to-action.
5. **"New Room" FAB** — unchanged (fixed bottom-right) + existing create-room modal unchanged.

### 2. Featured room selection

- Rank `@rooms_players` by number of present `users`, descending; the top entry is featured.
- **Fallback:** if every room has zero present users, feature the **newest** room (rooms already
  have insertion order / timestamps via `list_rooms`; use the newest). This guarantees the hero is
  never an awkward empty room and is deterministic.
- Implement as a pure helper, e.g. `featured_and_rest(rooms_players) :: {featured, rest}`, in
  `index.ex` (or a small view-model module). It must be recomputed whenever `@rooms_players`
  changes (presence/player updates), so featured selection stays live as people join/leave.
  - *Live re-rank consideration:* recompute derived assigns (`@featured`, `@rest`) inside the same
    `assign_*` helpers that currently update `@rooms_players`, so the hero can change rooms in real
    time. Keep the featured card's DOM id stable-by-room (`featured-#{room.id}`) so LiveView diffs
    cleanly when the featured room changes.

### 3. Featured hero card

- Large, full-width banner (stacks vertically on mobile; cover-left / info-right on `md+`).
- **Blurred-artwork backdrop:** the current cover art, blurred and dimmed, fills the hero
  background to pull ambient color from the artwork; a `tone-*`-based scrim keeps text legible in
  both themes. Falls back to a plain `tone-*` surface when there is no cover (idle room).
- Foreground content: crisp cover art, room **name**, **now-playing title + artist** (or a muted
  "Idle" / "Nothing playing" state), lock badge if protected, and the avatar stack of listeners.
- A subtle **brand-violet "now playing" pulse dot** when the room's player state is `:playing`.
- Whole hero is a single navigation target → `~p"/sessions/rooms/#{room}"` (same as today).

### 4. Room grid + cards

- **`room_grid` refactor** — replace the `grid-flow-col auto-cols-max` single row with a
  responsive wrapping grid: 1 col (mobile) → 2 (`sm`) → 3 (`md`) → 4 (`lg`) → 5 (`xl`). Cards size
  to the grid track (fluid), not the fixed `w-40 h-52`. Keep the component's existing slot-based
  interface (`modules`, `module_id`, `module_click`, inner block) so callers stay simple.
- **Card visual** — generous rounded card on a `tone-50` / `dark:tone-800` surface, soft shadow,
  border via `tone-200` (light). Hover: gentle lift (`-translate-y` + larger shadow + slight
  brightness), replacing today's brightness-only hover. Focus-visible ring in `brand` for
  keyboard nav.
- **Card content** — cover art (square, top), room **name** (truncated), **now-playing title**
  (truncated, muted when idle), avatar stack, lock badge overlay on the cover.

### 5. `PlayerPreview` refactor

- Keep rendering cover art / placeholder / lock badge, but:
  - Migrate placeholder colors from `bg-gray-*` / `text-zinc-*` to `tone-*` tokens.
  - Optionally accept a `size` / variant so the same component serves both the large hero cover and
    the standard grid cover, avoiding a second cover component.
  - Now-playing **text** (title/artist) is rendered by the card/hero templates (which own layout),
    reading `@player.title` / `@player.channel`; `PlayerPreview` stays focused on the visual cover.
    Guard for `nil` player and empty strings (idle rooms).

---

## Components touched

| File | Change |
|------|--------|
| `lib/livedj_web/live/sessions/room_live/index.html.heex` | New layout: header, featured hero, responsive grid, empty state; FAB/modal unchanged. |
| `lib/livedj_web/live/sessions/room_live/index.ex` | Derive `{featured, rest}` from `@rooms_players`; recompute on presence/player updates. No new subscriptions. |
| `lib/livedj_web/components/custom_components.ex` (`room_grid`) | Single-row → responsive wrapping grid; fluid card sizing; refined hover/focus. Preserve slot interface. |
| `lib/livedj_web/components/player_preview.ex` | `tone-*` migration; optional size/variant for hero vs grid reuse. |

New: possibly a small `featured_hero` function component (in `custom_components.ex`) and/or a
view-model helper for `featured_and_rest/1`. Keep each unit single-purpose.

---

## Behavior & edge cases

- **0 rooms** → empty state only (no hero, no grid).
- **1 room** → hero only, no grid.
- **All rooms empty (no presence)** → hero = newest room; cards/hero show idle now-playing state.
- **Idle / paused player** → no now-playing text (show muted idle label); no pulse dot; keep the
  existing paused pulse-animation behavior on the cover if desired.
- **No cover art** → musical-note placeholder (hero backdrop falls back to plain `tone-*` surface).
- **Protected room** → lock badge preserved on both hero and grid cards.
- **Live updates** → featured selection and card contents update in place as presence/player
  events arrive; featured room may change without a full reload.
- **Long text** → room name, track title, and artist all truncate.

## Accessibility

- Hero and each card are single, keyboard-focusable navigation targets with `focus-visible` ring
  (`brand`). Preserve existing `title` / `aria-label` on the lock badge. Ensure text contrast holds
  over the blurred hero backdrop in both light and dark via the scrim.

## Testing

- Follow existing patterns for `RoomLive.Index` tests; run via `make test` (not bare `mix test`).
- Cover: featured selection picks most-present room; empty-all fallback picks newest; empty-state
  renders with zero rooms; now-playing title renders when a player has a title and is hidden/idle
  otherwise; grid renders the non-featured rooms.
- Manual/visual check in light + dark and at least one alternate `data-tone` to confirm no
  hard-coded neutrals leaked in.

## Out of scope / future ideas

Listener count & LIVE badge, playlist-length indicator, search/filter/sort, and any admin-side
(`admin/.../room_live`) changes — deliberately excluded from this pass.
