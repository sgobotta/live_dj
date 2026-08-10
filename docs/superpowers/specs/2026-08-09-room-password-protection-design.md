# Password-protected rooms — design

**Date:** 2026-08-09
**Status:** Approved (pending spec review)

## Summary

Rooms can be optionally protected by a password. Setting a password gates
**access** to the room: a visitor who is not yet authorized is redirected to a
password challenge screen and must enter the correct password before they can
see or join the room. Protected rooms display a lock icon on their card in the
rooms list. The password can be set at creation time and edited (or removed)
later from the room page, using the same modal standard the app already uses for
other room actions.

## Decisions (from brainstorming)

- **Enforcement:** gate access via a challenge screen (not a cosmetic marker).
- **Edit rights:** anyone currently in the room can set/edit/remove the
  password. No room-owner concept is introduced (consistent with the app's
  existing open model where everyone controls playback, playlist, and chat).
- **Password storage:** hashed with `bcrypt_elixir` (already a dependency, used
  for user auth).
- **Authorization memory:** persists across reloads and revisits via the
  Phoenix **signed session** (server-set, tamper-proof), until the session
  expires.

## Security rationale (why the gate is a controller, not a LiveView)

The existing per-room display-name persistence uses a **client-written cookie**
(`livedj_display_name_<room_id>`) copied into the session by the
`put_display_names` router plug. That is fine for a preference but unacceptable
for an access gate: a client could forge the cookie to bypass the password.

Therefore authorization must live in the **Phoenix signed session**, set
**server-side**. LiveViews run over a WebSocket and cannot set session cookies,
so the verification step is a plain HTTP controller. The LiveView only *reads*
the resulting session value (via an `on_mount` guard).

## Components

### 1. Data model

- **Migration** — add `password_hash :string` (nullable) to `rooms`.
  `nil` means the room is public.
- **`Livedj.Sessions.Room` schema** — add:
  - `field :password_hash, :string`
  - `field :password, :string, virtual: true, redact: true`
- **Changesets:**
  - `changeset/2` (create): casts `:name` + `:password`. Password is optional;
    when present and non-blank, validate length (min 4, max 72 bytes — mirrors
    `Livedj.Accounts.User`) and hash via `Bcrypt.hash_pwd_salt/1` into
    `password_hash`. Slug behavior unchanged.
  - `password_changeset/2` (edit modal): casts only `:password`. A blank/empty
    submission **clears** protection (`password_hash -> nil`). A non-blank value
    is validated and hashed.
  - Hashing helper mirrors `User.maybe_hash_password/put_pass_hash`: only hash
    when the changeset is valid and a password change is present; delete the
    virtual `:password` from changes after hashing.

### 2. Context (`Livedj.Sessions`)

- `create_room/1`, `update_room/2` — unchanged call sites; they already run
  through `Room.changeset/2`, which now understands `:password`.
- `update_room_password/2` — new; runs `Room.password_changeset/2` and persists.
- `room_protected?/1` — `room.password_hash != nil`.
- `verify_room_password/2` — `Bcrypt.verify_pass(password, room.password_hash)`;
  calls `Bcrypt.no_user_verify/0` and returns `false` when the room is
  unprotected or the input is blank, to avoid timing leaks.
- `authorization_fingerprint/1` — short, stable token derived from
  `password_hash` (e.g. first 16 hex chars of `:crypto.hash(:sha256,
  password_hash)`). Used so that changing/removing the password invalidates
  previously granted authorizations.

### 3. Access gate (enforcement)

- **`LivedjWeb.RoomAuth` `on_mount` hook** (`:ensure_room_access`) added to the
  `RoomLive.Show` `live_session`. On mount:
  - Load the room. If not protected → allow (`{:cont, socket}`).
  - If protected, read `session["authorized_rooms"]` (a
    `%{room_id => fingerprint}` map). If it contains the room id with a
    fingerprint matching the room's current `authorization_fingerprint/1` →
    allow.
  - Otherwise → `{:halt, redirect(to: ~p"/sessions/rooms/:id/unlock")}`.
  - Runs on both the disconnected and connected mount; the session is available
    in both, so the redirect is reliable.
- **`LivedjWeb.RoomUnlockController`** (dead views, plain HTTP):
  - `new` (GET `/sessions/rooms/:id/unlock`) — renders a standalone challenge
    screen styled like the app: room name + a single password input + submit.
    If the room is not protected, redirect straight to the room.
  - `create` (POST `/sessions/rooms/:id/unlock`) — verifies via
    `verify_room_password/2`. On success:
    `put_session(conn, "authorized_rooms", Map.put(existing, room_id,
    fingerprint))` then redirect to `/sessions/rooms/:id`. On failure: re-render
    the challenge with an error flash.
- Because the value is in the signed session cookie, authorization is both
  tamper-proof and persistent across reloads/revisits.

### 4. Room creation

- Add an optional **password input** to `RoomLive.FormComponent`, below the name
  field, using the standard `<.input type="password">` with a label and
  placeholder/help text indicating it is optional. Empty = public room. No other
  changes to the create/`:new` flow (still navigates to `/welcome` on success).

### 5. Edit password on the room page (modal standard)

- New live-action `:settings` on `RoomLive.Show`, route
  `/sessions/rooms/:id/settings`, opened via `push_patch` — exactly mirroring
  the `:welcome` / `:help` pattern.
- New `password_modal/1` in `LivedjWeb.SessionModals` using the standard
  `<.modal>`:
  - A small form with a password field and a **Save** button.
  - A **Remove password** action shown only when the room is currently
    protected (submits a blank password → clears protection).
  - Header/subtitle communicating current state (protected vs. public).
- Trigger: a lock button in the session header (`session.html.heex`), alongside
  share/help/chat, with a tooltip. Available to **anyone in the room**.
- Submitting calls `Sessions.update_room_password/2`. Changing the password
  rotates the fingerprint, so **other** sessions are re-prompted on their next
  visit (intended). The editor remains in the room for the current visit; on a
  later reload they re-enter like anyone else.

### 6. Lock icon on the rooms list

- In `index.html.heex`'s room card, render `<.icon name="hero-lock-closed">`
  as a small badge in a corner (top-right, over the player preview) when
  `Sessions.room_protected?(room)` is true.

## Cross-cutting

- **i18n:** all new user-facing strings via `gettext`; add Spanish (`es`)
  translations (the app ships `es`).
- **Accessibility:** the challenge screen and modal inputs have labels; the lock
  badge has an appropriate `aria-label`/`title`.

## Testing (TDD)

- **Schema** (`Room` changeset): password hashing on create; optional (public)
  create; length validation (min 4 / max 72); `password_changeset` sets and
  clears protection; virtual `:password` never persisted / is redacted.
- **Context** (`Sessions`): `create_room` with/without password;
  `update_room_password` set + clear; `verify_room_password` correct/incorrect/
  unprotected; `room_protected?`; `authorization_fingerprint` stability and
  change-on-rotation.
- **Controller** (`RoomUnlockController`): `new` renders for protected room and
  redirects for public room; `create` with correct password sets session +
  redirects; `create` with wrong password re-renders with error and no session;
  fingerprint stored matches room.
- **`on_mount` guard**: unauthorized visitor to a protected room is redirected to
  `/unlock`; authorized session passes; public room bypasses; stale fingerprint
  (after password change) is rejected.
- **FormComponent**: creating a room with a password produces a protected room.
- **Edit modal**: setting a password protects the room; removing clears it.
- **Rooms list**: lock icon renders only for protected rooms.

## Out of scope

- Room ownership / per-user permissions.
- Rate limiting / lockout on repeated wrong passwords (can be a later hardening
  pass).
- Editing the room **name** from the room page (not requested).
- Sharing that embeds the password in the link.
