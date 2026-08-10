# Password-Protected Rooms Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let rooms be optionally protected by a password that gates access via a challenge screen, with a lock badge on protected room cards and an in-room modal to set/change/remove the password.

**Architecture:** The password is hashed with `bcrypt_elixir` and stored on the `rooms` table. Access is enforced by a LiveView `on_mount` guard that redirects unauthorized visitors to a plain HTTP controller challenge screen; on correct password the controller writes a tamper-proof entry into the Phoenix signed session, so authorization persists across reloads. Everyone in a room may edit the password (no ownership model), mirroring the app's existing open-collaboration model.

**Tech Stack:** Elixir, Phoenix LiveView, Ecto, `bcrypt_elixir` (already a dependency), Tailwind, gettext.

## Global Constraints

- Password hashing: `Bcrypt.hash_pwd_salt/1` and `Bcrypt.verify_pass/2` (matches `Livedj.Accounts.User`).
- Password length: min 4, max 72 bytes.
- `rooms.password_hash` is nullable; `nil` == public room.
- Authorization is stored **server-side** in the Phoenix session under key `"authorized_rooms"` as `%{room_id => fingerprint}`. Never trust a client-written cookie for the gate.
- All new user-facing strings go through `gettext`; Spanish (`es`) translations must be added.
- Follow existing formatting; `mix format` runs on pre-commit (a hook is configured).
- Run tests with `mix test <path>`.

---

### Task 1: Migration + schema field + create-changeset password hashing

**Files:**
- Create: `priv/repo/migrations/20260809120000_add_password_hash_to_rooms.exs`
- Modify: `lib/livedj/sessions/room.ex`
- Test: `test/livedj/sessions/room_test.exs` (create)

**Interfaces:**
- Produces: `Livedj.Sessions.Room` gains `field :password_hash, :string` and virtual `field :password, :string, redact: true`. `Room.changeset/2` now casts `:name` + `:password`; a non-blank password (≥4 bytes) is hashed into `:password_hash`; a blank/absent password leaves the room public.

- [ ] **Step 1: Write the failing test**

Create `test/livedj/sessions/room_test.exs`:

```elixir
defmodule Livedj.Sessions.RoomTest do
  @moduledoc false
  use Livedj.DataCase, async: true

  alias Livedj.Sessions.Room

  describe "changeset/2 password" do
    test "hashes a valid password into password_hash" do
      changeset = Room.changeset(%Room{}, %{"name" => "n", "password" => "secret"})

      assert changeset.valid?
      hash = Ecto.Changeset.get_change(changeset, :password_hash)
      assert is_binary(hash)
      assert Bcrypt.verify_pass("secret", hash)
      refute Ecto.Changeset.get_change(changeset, :password)
    end

    test "leaves password_hash nil when password is blank (public room)" do
      changeset = Room.changeset(%Room{}, %{"name" => "n", "password" => ""})

      assert changeset.valid?
      refute Ecto.Changeset.get_change(changeset, :password_hash)
    end

    test "leaves password_hash nil when password is absent (public room)" do
      changeset = Room.changeset(%Room{}, %{"name" => "n"})

      assert changeset.valid?
      refute Ecto.Changeset.get_change(changeset, :password_hash)
    end

    test "rejects a too-short password" do
      changeset = Room.changeset(%Room{}, %{"name" => "n", "password" => "ab"})

      refute changeset.valid?
      assert %{password: [_]} = errors_on(changeset)
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/livedj/sessions/room_test.exs`
Expected: FAIL — `:password`/`:password_hash` are not fields yet.

- [ ] **Step 3: Write the migration**

Create `priv/repo/migrations/20260809120000_add_password_hash_to_rooms.exs`:

```elixir
defmodule Livedj.Repo.Migrations.AddPasswordHashToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :password_hash, :string
    end
  end
end
```

- [ ] **Step 4: Update the schema + changeset**

Replace the contents of `lib/livedj/sessions/room.ex` with:

```elixir
defmodule Livedj.Sessions.Room do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @password_min 4
  @password_max 72

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :name, :string
    field :slug, :string
    field :password_hash, :string
    field :password, :string, virtual: true, redact: true

    timestamps()
  end

  @doc """
  Changeset for creating/updating a room. Casts an optional `:password`; a
  non-blank value is validated and hashed into `:password_hash`, a blank/absent
  value leaves the room public.
  """
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :password])
    |> validate_required([:name])
    |> maybe_put_slug()
    |> maybe_hash_password()
  end

  @doc """
  Changeset dedicated to editing the password from the room page. A blank value
  clears protection (`password_hash` -> nil); a non-blank value is validated and
  hashed.
  """
  def password_changeset(room, attrs) do
    room
    |> cast(attrs, [:password], empty_values: [])
    |> clear_or_hash_password()
  end

  defp maybe_hash_password(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      "" -> delete_change(changeset, :password)
      _password -> put_password_hash(changeset)
    end
  end

  defp clear_or_hash_password(changeset) do
    case get_change(changeset, :password) do
      blank when blank in [nil, ""] -> put_change(changeset, :password_hash, nil)
      _password -> put_password_hash(changeset)
    end
  end

  defp put_password_hash(changeset) do
    changeset =
      validate_length(changeset, :password,
        min: @password_min,
        max: @password_max,
        count: :bytes
      )

    if changeset.valid? do
      changeset
      |> put_change(:password_hash, Bcrypt.hash_pwd_salt(get_change(changeset, :password)))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_put_slug(%Ecto.Changeset{data: %{slug: nil}} = changeset) do
    put_change(changeset, :slug, Ecto.UUID.generate())
  end

  defp maybe_put_slug(changeset), do: changeset
end
```

- [ ] **Step 5: Run migration + tests**

Run: `mix ecto.migrate && mix test test/livedj/sessions/room_test.exs`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add priv/repo/migrations/20260809120000_add_password_hash_to_rooms.exs lib/livedj/sessions/room.ex test/livedj/sessions/room_test.exs
git commit -m "Add hashed password field and create-changeset to Room"
```

---

### Task 2: `password_changeset` set/clear behavior

**Files:**
- Modify: `test/livedj/sessions/room_test.exs`

**Interfaces:**
- Consumes: `Room.password_changeset/2` from Task 1.

- [ ] **Step 1: Write the failing test**

Append inside `test/livedj/sessions/room_test.exs`:

```elixir
  describe "password_changeset/2" do
    test "sets a hashed password" do
      changeset = Room.password_changeset(%Room{}, %{"password" => "hunter2"})

      assert changeset.valid?
      hash = Ecto.Changeset.get_change(changeset, :password_hash)
      assert Bcrypt.verify_pass("hunter2", hash)
    end

    test "clears the password when blank" do
      room = %Room{password_hash: "existing-hash"}
      changeset = Room.password_changeset(room, %{"password" => ""})

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :password_hash) == nil
    end

    test "rejects a too-short password" do
      changeset = Room.password_changeset(%Room{}, %{"password" => "ab"})
      refute changeset.valid?
    end
  end
```

- [ ] **Step 2: Run test**

Run: `mix test test/livedj/sessions/room_test.exs`
Expected: PASS (behavior already implemented in Task 1). If any fail, fix `password_changeset` in `room.ex` before continuing.

- [ ] **Step 3: Commit**

```bash
git add test/livedj/sessions/room_test.exs
git commit -m "Cover Room.password_changeset set/clear behavior"
```

---

### Task 3: Sessions context helpers

**Files:**
- Modify: `lib/livedj/sessions.ex`
- Test: `test/livedj/sessions_test.exs`

**Interfaces:**
- Produces:
  - `Sessions.room_protected?(room) :: boolean()`
  - `Sessions.verify_room_password(room, password) :: boolean()`
  - `Sessions.authorization_fingerprint(room) :: binary() | nil`
  - `Sessions.update_room_password(room, attrs) :: {:ok, Room.t()} | {:error, Ecto.Changeset.t()}`

- [ ] **Step 1: Write the failing tests**

Append a new `describe` block to `test/livedj/sessions_test.exs` (inside the module, after the existing `describe "rooms"`):

```elixir
  describe "room password protection" do
    import Livedj.SessionsFixtures

    test "room_protected?/1 reflects presence of a password" do
      assert Sessions.room_protected?(room_fixture(%{password: "secret1"}))
      refute Sessions.room_protected?(room_fixture())
    end

    test "verify_room_password/2 accepts the correct password" do
      room = room_fixture(%{password: "secret1"})
      assert Sessions.verify_room_password(room, "secret1")
    end

    test "verify_room_password/2 rejects an incorrect password" do
      room = room_fixture(%{password: "secret1"})
      refute Sessions.verify_room_password(room, "wrong")
    end

    test "verify_room_password/2 returns false for a public room" do
      refute Sessions.verify_room_password(room_fixture(), "anything")
    end

    test "authorization_fingerprint/1 is nil for public rooms, stable for protected" do
      assert Sessions.authorization_fingerprint(room_fixture()) == nil

      room = room_fixture(%{password: "secret1"})
      fp = Sessions.authorization_fingerprint(room)
      assert is_binary(fp)
      assert Sessions.authorization_fingerprint(room) == fp
    end

    test "update_room_password/2 sets then clears protection" do
      room = room_fixture()

      {:ok, protected} = Sessions.update_room_password(room, %{"password" => "secret1"})
      assert Sessions.room_protected?(protected)
      fp = Sessions.authorization_fingerprint(protected)

      {:ok, cleared} = Sessions.update_room_password(protected, %{"password" => ""})
      refute Sessions.room_protected?(cleared)
      refute Sessions.authorization_fingerprint(cleared) == fp
    end
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/livedj/sessions_test.exs`
Expected: FAIL — functions undefined.

- [ ] **Step 3: Implement the helpers**

In `lib/livedj/sessions.ex`, within the "Repo operations" section (near `change_room/2`), add:

```elixir
  @doc "Returns true when the room has a password set."
  @spec room_protected?(Room.t()) :: boolean()
  def room_protected?(%Room{password_hash: hash}), do: not is_nil(hash)

  @doc """
  Verifies a plaintext password against a room's hash. Runs a dummy verify for
  unprotected rooms to avoid timing leaks, and always returns false for them.
  """
  @spec verify_room_password(Room.t(), binary()) :: boolean()
  def verify_room_password(%Room{password_hash: nil}, _password) do
    Bcrypt.no_user_verify()
    false
  end

  def verify_room_password(%Room{password_hash: hash}, password)
      when is_binary(password) do
    Bcrypt.verify_pass(password, hash)
  end

  def verify_room_password(%Room{}, _password), do: false

  @doc """
  Returns a short, stable fingerprint of the room's password hash, used to key
  session authorization so that changing the password re-locks other sessions.
  Returns nil for public rooms.
  """
  @spec authorization_fingerprint(Room.t()) :: binary() | nil
  def authorization_fingerprint(%Room{password_hash: nil}), do: nil

  def authorization_fingerprint(%Room{password_hash: hash}) do
    :crypto.hash(:sha256, hash) |> Base.encode16(case: :lower) |> binary_part(0, 16)
  end

  @doc "Sets, changes, or clears a room's password."
  @spec update_room_password(Room.t(), map()) ::
          {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def update_room_password(%Room{} = room, attrs) do
    room
    |> Room.password_changeset(attrs)
    |> Repo.update()
  end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/livedj/sessions_test.exs`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/livedj/sessions.ex test/livedj/sessions_test.exs
git commit -m "Add room password context helpers"
```

---

### Task 4: Access guard (`RoomAuth` on_mount) + router wiring

**Files:**
- Create: `lib/livedj_web/room_auth.ex`
- Modify: `lib/livedj_web/router.ex` (add the guard to the `:sessions_show` live_session, add unlock routes placeholder comment — routes themselves land in Task 5)
- Test: `test/livedj_web/live/sessions/room_live/show_test.exs`

**Interfaces:**
- Consumes: `Sessions.room_protected?/1`, `Sessions.authorization_fingerprint/1`, `Sessions.get_room!/1`.
- Produces: `LivedjWeb.RoomAuth.on_mount(:ensure_room_access, params, session, socket)` that `:cont`s for public/authorized rooms and `{:halt, redirect(to: "/sessions/rooms/:id/unlock")}` otherwise. Reads session key `"authorized_rooms"` (`%{room_id => fingerprint}`).

- [ ] **Step 1: Write the failing test**

Append to `test/livedj/../show_test.exs` a new describe block (inside the module):

```elixir
  describe "password gate" do
    test "redirects an unauthorized visitor of a protected room to /unlock", %{
      conn: conn
    } do
      room = room_fixture(%{password: "secret1"})

      assert {:error, {:redirect, %{to: to}}} =
               live(conn, ~p"/sessions/rooms/#{room}")

      assert to == ~p"/sessions/rooms/#{room}/unlock"
    end

    test "allows a visitor whose session holds a matching fingerprint", %{
      conn: conn
    } do
      room = room_fixture(%{password: "secret1"})
      fingerprint = Livedj.Sessions.authorization_fingerprint(room)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session("authorized_rooms", %{room.id => fingerprint})

      assert {:ok, _view, _html} = live(conn, ~p"/sessions/rooms/#{room}")
    end

    test "allows any visitor of a public room", %{conn: conn, room: room} do
      assert {:ok, _view, _html} = live(conn, ~p"/sessions/rooms/#{room}")
    end
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/livedj_web/live/sessions/room_live/show_test.exs`
Expected: FAIL — protected room currently loads instead of redirecting.

- [ ] **Step 3: Create the guard**

Create `lib/livedj_web/room_auth.ex`:

```elixir
defmodule LivedjWeb.RoomAuth do
  @moduledoc """
  LiveView `on_mount` guard enforcing room password protection. Unauthorized
  visitors of a protected room are redirected to the password challenge screen.
  """
  use LivedjWeb, :verified_routes

  import Phoenix.LiveView, only: [redirect: 2]

  alias Livedj.Sessions
  alias Livedj.Sessions.Exceptions.SessionRoomError
  alias Livedj.Sessions.Room

  def on_mount(:ensure_room_access, %{"id" => id}, session, socket) do
    room = Sessions.get_room!(id)

    if authorized?(room, session) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/sessions/rooms/#{room}/unlock")}
    end
  rescue
    SessionRoomError ->
      {:halt, redirect(socket, to: ~p"/")}
  end

  defp authorized?(%Room{password_hash: nil}, _session), do: true

  defp authorized?(%Room{} = room, session) do
    authorized = Map.get(session, "authorized_rooms", %{})
    Map.get(authorized, room.id) == Sessions.authorization_fingerprint(room)
  end
end
```

- [ ] **Step 4: Wire the guard into the router**

In `lib/livedj_web/router.ex`, add `{LivedjWeb.RoomAuth, :ensure_room_access}` to the `:sessions_show` live_session `on_mount` list:

```elixir
    live_session :sessions_show,
      on_mount: [
        {LivedjWeb.UserAuth, :mount_current_user},
        {LivedjWeb.Theme, :fetch_theme},
        {LivedjWeb.RoomAuth, :ensure_room_access}
      ],
      root_layout: {LivedjWeb.Layouts, :root_session} do
```

- [ ] **Step 5: Run test to verify it passes**

Run: `mix test test/livedj_web/live/sessions/room_live/show_test.exs`
Expected: PASS. All three gate tests pass — the redirect fires from `on_mount`, and `~p".../unlock"` resolves to the correct string even though the route is added in Task 5 (verified routes emit a compile warning for the not-yet-defined route but still build the path). The warning disappears after Task 5.

- [ ] **Step 6: Commit**

```bash
git add lib/livedj_web/room_auth.ex lib/livedj_web/router.ex test/livedj_web/live/sessions/room_live/show_test.exs
git commit -m "Add RoomAuth on_mount password gate"
```

---

### Task 5: Unlock challenge controller + routes

**Files:**
- Create: `lib/livedj_web/controllers/room_unlock_controller.ex`
- Create: `lib/livedj_web/controllers/room_unlock_html.ex`
- Create: `lib/livedj_web/controllers/room_unlock_html/new.html.heex`
- Modify: `lib/livedj_web/router.ex`
- Test: `test/livedj_web/controllers/room_unlock_controller_test.exs`

**Interfaces:**
- Consumes: `Sessions.get_room!/1`, `Sessions.room_protected?/1`, `Sessions.verify_room_password/2`, `Sessions.authorization_fingerprint/1`.
- Produces: GET `/sessions/rooms/:room_id/unlock` (`:new`) and POST `/sessions/rooms/:room_id/unlock` (`:create`). On correct password, sets session `"authorized_rooms"` and redirects to `~p"/sessions/rooms/:id"`.

- [ ] **Step 1: Write the failing test**

Create `test/livedj_web/controllers/room_unlock_controller_test.exs`:

```elixir
defmodule LivedjWeb.RoomUnlockControllerTest do
  use LivedjWeb.ConnCase, async: true

  import Livedj.SessionsFixtures

  describe "GET /sessions/rooms/:room_id/unlock" do
    test "renders the challenge for a protected room", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})
      conn = get(conn, ~p"/sessions/rooms/#{room}/unlock")
      response = html_response(conn, 200)
      assert response =~ room.name
      assert response =~ "password"
    end

    test "redirects to the room for a public room", %{conn: conn} do
      room = room_fixture()
      conn = get(conn, ~p"/sessions/rooms/#{room}/unlock")
      assert redirected_to(conn) == ~p"/sessions/rooms/#{room}"
    end
  end

  describe "POST /sessions/rooms/:room_id/unlock" do
    test "authorizes and redirects on correct password", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})

      conn =
        post(conn, ~p"/sessions/rooms/#{room}/unlock", %{"password" => "secret1"})

      assert redirected_to(conn) == ~p"/sessions/rooms/#{room}"

      assert get_session(conn, "authorized_rooms") ==
               %{room.id => Livedj.Sessions.authorization_fingerprint(room)}
    end

    test "re-renders with an error on wrong password", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})

      conn =
        post(conn, ~p"/sessions/rooms/#{room}/unlock", %{"password" => "nope"})

      assert html_response(conn, 200) =~ room.name
      refute get_session(conn, "authorized_rooms")
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/livedj_web/controllers/room_unlock_controller_test.exs`
Expected: FAIL — no route/controller.

- [ ] **Step 3: Create the controller**

Create `lib/livedj_web/controllers/room_unlock_controller.ex`:

```elixir
defmodule LivedjWeb.RoomUnlockController do
  use LivedjWeb, :controller

  alias Livedj.Sessions

  def new(conn, %{"room_id" => id}) do
    room = Sessions.get_room!(id)

    if Sessions.room_protected?(room) do
      render(conn, :new, room: room, error: nil, page_title: room.name)
    else
      redirect(conn, to: ~p"/sessions/rooms/#{room}")
    end
  end

  def create(conn, %{"room_id" => id, "password" => password}) do
    room = Sessions.get_room!(id)

    if Sessions.verify_room_password(room, password) do
      authorized = get_session(conn, "authorized_rooms") || %{}

      conn
      |> put_session(
        "authorized_rooms",
        Map.put(authorized, room.id, Sessions.authorization_fingerprint(room))
      )
      |> redirect(to: ~p"/sessions/rooms/#{room}")
    else
      conn
      |> render(:new,
        room: room,
        error: gettext("Incorrect password. Please try again."),
        page_title: room.name
      )
    end
  end
end
```

- [ ] **Step 4: Create the HTML module + template**

Create `lib/livedj_web/controllers/room_unlock_html.ex`:

```elixir
defmodule LivedjWeb.RoomUnlockHTML do
  use LivedjWeb, :html

  embed_templates "room_unlock_html/*"
end
```

Create `lib/livedj_web/controllers/room_unlock_html/new.html.heex`:

```heex
<div class="min-h-dvh flex items-center justify-center bg-tone-200 dark:bg-tone-800 px-4">
  <div class="w-full max-w-sm rounded-2xl bg-tone-50 dark:bg-tone-900 border border-tone-300 dark:border-tone-700 shadow-lg p-6">
    <div class="flex flex-col items-center gap-2 mb-6">
      <.icon name="hero-lock-closed" class="h-8 w-8 text-tone-700 dark:text-tone-300" />
      <h1 class="text-lg font-semibold text-tone-900 dark:text-tone-100 text-center">
        {@room.name}
      </h1>
      <p class="text-sm text-tone-600 dark:text-tone-400 text-center">
        {gettext("This room is password protected")}
      </p>
    </div>

    <%= if @error do %>
      <p class="mb-3 text-sm text-red-600 dark:text-red-400 text-center">{@error}</p>
    <% end %>

    <.form :let={_f} for={%{}} action={~p"/sessions/rooms/#{@room}/unlock"} method="post">
      <input
        type="password"
        name="password"
        autofocus
        placeholder={gettext("Password")}
        class="w-full rounded-lg border border-tone-300 dark:border-tone-600 bg-transparent px-3 py-2 text-tone-900 dark:text-tone-100 focus:ring-2 focus:ring-tone-900 focus:dark:ring-tone-50"
      />
      <.button class="mt-4 w-full">{gettext("Enter room")}</.button>
    </.form>
  </div>
</div>
```

- [ ] **Step 5: Add the routes**

In `lib/livedj_web/router.ex`, inside `scope "/", LivedjWeb do` (which uses `pipe_through :browser`), after the `get "/", PageController, :home` line, add:

```elixir
    get "/sessions/rooms/:room_id/unlock", RoomUnlockController, :new
    post "/sessions/rooms/:room_id/unlock", RoomUnlockController, :create
```

- [ ] **Step 6: Run tests**

Run: `mix test test/livedj_web/controllers/room_unlock_controller_test.exs test/livedj_web/live/sessions/room_live/show_test.exs`
Expected: PASS (including the previously-deferred redirect test from Task 4).

- [ ] **Step 7: Commit**

```bash
git add lib/livedj_web/controllers/room_unlock_controller.ex lib/livedj_web/controllers/room_unlock_html.ex lib/livedj_web/controllers/room_unlock_html/new.html.heex lib/livedj_web/router.ex test/livedj_web/controllers/room_unlock_controller_test.exs
git commit -m "Add room unlock challenge controller"
```

---

### Task 6: Optional password field on room creation

**Files:**
- Modify: `lib/livedj_web/live/sessions/room_live/form_component.ex`
- Test: `test/livedj_web/live/sessions/room_live/index_test.exs` (create if absent)

**Interfaces:**
- Consumes: `Room.changeset/2` already handling `:password` (Task 1); the create flow already calls `Sessions.create_room/1`.
- Produces: The create form submits a `password` param; creating with a non-blank password yields a protected room.

- [ ] **Step 1: Write the failing test**

Create (or append to) `test/livedj_web/live/sessions/room_live/index_test.exs`:

```elixir
defmodule LivedjWeb.Sessions.RoomLive.IndexTest do
  @moduledoc false
  use LivedjWeb.ConnCase

  import Phoenix.LiveViewTest
  import Livedj.SessionsFixtures

  setup :register_and_log_in_user

  test "creates a protected room when a password is provided", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sessions/rooms/new")

    view
    |> form("#room-form", room: %{name: "Locked Room", password: "secret1"})
    |> render_submit()

    room = Enum.find(Livedj.Sessions.list_rooms(), &(&1.name == "Locked Room"))
    assert Livedj.Sessions.room_protected?(room)
  end

  test "creates a public room when no password is provided", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sessions/rooms/new")

    view
    |> form("#room-form", room: %{name: "Open Room", password: ""})
    |> render_submit()

    room = Enum.find(Livedj.Sessions.list_rooms(), &(&1.name == "Open Room"))
    refute Livedj.Sessions.room_protected?(room)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/livedj_web/live/sessions/room_live/index_test.exs`
Expected: FAIL — no password input in the form.

- [ ] **Step 3: Add the password input**

In `lib/livedj_web/live/sessions/room_live/form_component.ex`, add a password input after the name `<.input>` (before the `<:actions>` slot):

```elixir
        <.input
          field={@form[:password]}
          type="password"
          label={gettext("Password (optional)")}
          placeholder={gettext("Leave blank for a public room")}
          class="focus:ring-2 focus:ring-tone-900 focus:dark:ring-tone-50"
        />
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/livedj_web/live/sessions/room_live/index_test.exs`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/livedj_web/live/sessions/room_live/form_component.ex test/livedj_web/live/sessions/room_live/index_test.exs
git commit -m "Add optional password field to room creation form"
```

---

### Task 7: In-room edit-password modal

**Files:**
- Modify: `lib/livedj_web/components/session_modals.ex` (add `password_modal/1`)
- Modify: `lib/livedj_web/components/layouts/session.html.heex` (render modal + header button)
- Modify: `lib/livedj_web/live/sessions/room_live/show.ex` (route action + events)
- Modify: `lib/livedj_web/router.ex` (add `:settings` route)
- Test: `test/livedj_web/live/sessions/room_live/show_test.exs`

**Interfaces:**
- Consumes: `Sessions.update_room_password/2`, `Sessions.room_protected?/1`.
- Produces: live action `:settings` at `~p"/sessions/rooms/:id/settings"`; events `open_settings_modal`, `save_room_password`, `remove_room_password` on `RoomLive.Show`.

- [ ] **Step 1: Write the failing test**

Append to `test/livedj_web/live/sessions/room_live/show_test.exs`:

```elixir
  describe "edit password modal" do
    test "sets a password from the settings modal", %{conn: conn, room: room} do
      {:ok, view, _html} = live(conn, ~p"/sessions/rooms/#{room}/settings")

      view
      |> form("#room-password-form", %{password: "secret1"})
      |> render_submit()

      assert Livedj.Sessions.room_protected?(Livedj.Sessions.get_room!(room.id))
    end

    test "removes an existing password", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})
      fingerprint = Livedj.Sessions.authorization_fingerprint(room)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session("authorized_rooms", %{room.id => fingerprint})

      {:ok, view, _html} = live(conn, ~p"/sessions/rooms/#{room}/settings")

      view |> element("#remove-room-password") |> render_click()

      refute Livedj.Sessions.room_protected?(Livedj.Sessions.get_room!(room.id))
    end
  end
```

Note: `register_and_log_in_user` runs in `setup`; the `%{room: room}` from the existing `create_room` setup is a public room, so `/settings` is reachable without authorization.

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/livedj_web/live/sessions/room_live/show_test.exs`
Expected: FAIL — no `:settings` route/action/modal.

- [ ] **Step 3: Add the `:settings` route**

In `lib/livedj_web/router.ex`, inside the `:sessions_show` live_session scope, add:

```elixir
        live "/rooms/:id/settings", RoomLive.Show, :settings
```

- [ ] **Step 4: Add the modal component**

In `lib/livedj_web/components/session_modals.ex`, add:

```elixir
  attr :room, :map, required: true
  attr :show, :boolean, required: true

  def password_modal(assigns) do
    assigns = assign(assigns, :protected, not is_nil(assigns.room.password_hash))

    ~H"""
    <.modal
      :if={@show}
      id="room-password-modal"
      show
      on_cancel={JS.patch(~p"/sessions/rooms/#{@room}")}
    >
      <.header>
        {gettext("Room password")}
        <:subtitle>
          <%= if @protected do %>
            {gettext("This room is protected. Update or remove its password.")}
          <% else %>
            {gettext("Add a password to protect this room.")}
          <% end %>
        </:subtitle>
      </.header>

      <.form
        for={%{}}
        id="room-password-form"
        phx-submit="save_room_password"
        class="mt-6 flex flex-col gap-4"
      >
        <input
          type="password"
          name="password"
          placeholder={gettext("New password")}
          class="w-full rounded-lg border border-tone-300 dark:border-tone-600 bg-transparent px-3 py-2 text-tone-900 dark:text-tone-100 focus:ring-2 focus:ring-tone-900 focus:dark:ring-tone-50"
        />
        <div class="flex items-center justify-between gap-2">
          <button
            :if={@protected}
            type="button"
            id="remove-room-password"
            phx-click="remove_room_password"
            class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline"
          >
            {gettext("Remove password")}
          </button>
          <.button phx-disable-with={gettext("Saving...")} class="ml-auto">
            {gettext("Save")}
          </.button>
        </div>
      </.form>
    </.modal>
    """
  end
```

- [ ] **Step 5: Render the modal + header button in the layout**

In `lib/livedj_web/components/layouts/session.html.heex`, add after the `help_modal` block:

```heex
<.password_modal
  room={assigns[:room]}
  show={assigns[:live_action] == :settings}
/>
```

And add a header button next to the share button (inside the `<%= if assigns[:room] do %>` block):

```heex
<div class="relative group">
  <button
    id="settings-btn"
    phx-click="open_settings_modal"
    class="text-tone-700 dark:text-tone-300 hover:text-tone-900 dark:hover:text-tone-50 transition-colors duration-150 cursor-pointer"
  >
    <.icon name="hero-lock-closed" class="h-5 w-5" />
  </button>
  <.tooltip position={:below} class="left-1/2 -translate-x-1/2 z-30">
    {gettext("Room password")}
  </.tooltip>
</div>
```

- [ ] **Step 6: Add the LiveView action + event handlers**

In `lib/livedj_web/live/sessions/room_live/show.ex`, add an `apply_action` clause (alongside the others):

```elixir
  defp apply_action(socket, :settings, _params) do
    assign(socket, :page_title, "#{socket.assigns.room.name}")
  end
```

And add event handlers (near `open_help_modal`):

```elixir
  def handle_event("open_settings_modal", _params, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/sessions/rooms/#{socket.assigns.room}/settings")}
  end

  def handle_event("save_room_password", %{"password" => password}, socket) do
    save_password(socket, %{"password" => password})
  end

  def handle_event("remove_room_password", _params, socket) do
    save_password(socket, %{"password" => ""})
  end

  defp save_password(socket, attrs) do
    case Sessions.update_room_password(socket.assigns.room, attrs) do
      {:ok, room} ->
        {:noreply,
         socket
         |> assign(:room, room)
         |> put_flash(:info, gettext("Room password updated"))
         |> push_patch(to: ~p"/sessions/rooms/#{room}")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("Password must be at least 4 characters")
         )}
    end
  end
```

- [ ] **Step 7: Run test to verify it passes**

Run: `mix test test/livedj_web/live/sessions/room_live/show_test.exs`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/livedj_web/components/session_modals.ex lib/livedj_web/components/layouts/session.html.heex lib/livedj_web/live/sessions/room_live/show.ex lib/livedj_web/router.ex test/livedj_web/live/sessions/room_live/show_test.exs
git commit -m "Add in-room edit-password modal"
```

---

### Task 8: Lock badge on protected room cards

**Files:**
- Modify: `lib/livedj_web/live/sessions/room_live/index.html.heex`
- Test: `test/livedj_web/live/sessions/room_live/index_test.exs`

**Interfaces:**
- Consumes: `Sessions.room_protected?/1`.

- [ ] **Step 1: Write the failing test**

Append to `test/livedj_web/live/sessions/room_live/index_test.exs`:

```elixir
  test "shows a lock badge only on protected rooms", %{conn: conn} do
    _public = room_fixture(%{name: "Public Room"})
    _locked = room_fixture(%{name: "Locked Room", password: "secret1"})

    {:ok, _view, html} = live(conn, ~p"/sessions/rooms")

    assert html =~ "room-lock-badge"
    # exactly one badge (only the protected room)
    assert length(String.split(html, "room-lock-badge")) == 2
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/livedj_web/live/sessions/room_live/index_test.exs`
Expected: FAIL — no badge markup (the "lock badge" test fails).

- [ ] **Step 3: Add the badge**

In `lib/livedj_web/live/sessions/room_live/index.html.heex`, inside the card's `<div class="flex flex-col">` (wrapping the player preview), add a relatively-positioned badge. Wrap the player preview `<.live_component>` in a `relative` container and overlay the icon:

```heex
      <div class="relative flex flex-col">
        <div
          :if={Livedj.Sessions.room_protected?(room)}
          id={"room-lock-badge-#{room.id}"}
          class="room-lock-badge absolute top-1 right-1 z-10 rounded-full bg-tone-900/70 dark:bg-tone-50/70 p-1"
          title={gettext("Password protected")}
          aria-label={gettext("Password protected")}
        >
          <.icon name="hero-lock-closed" class="h-3.5 w-3.5 text-tone-50 dark:text-tone-900" />
        </div>
        <.live_component
          id={"player-preview-#{room.id}"}
          player={player}
          module={LivedjWeb.PlayerPreview}
          rooms_players={@rooms_players}
        />
        <div class="
          h-12 w-40 px-2 font-semibold
          text-tone-900 dark:text-tone-100
        ">
          <p class="font-normal text-xs truncate h-5">
            {room.name}
          </p>
          <.mini_avatar_stack users={users} />
        </div>
      </div>
```

(This replaces the existing `<div class="flex flex-col"> ... </div>` block; the only changes are the `relative` class on the outer div and the new badge div.)

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/livedj_web/live/sessions/room_live/index_test.exs`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/livedj_web/live/sessions/room_live/index.html.heex test/livedj_web/live/sessions/room_live/index_test.exs
git commit -m "Add lock badge to protected room cards"
```

---

### Task 9: Translations + full-suite verification

**Files:**
- Modify: `priv/gettext/**` (regenerated), especially `priv/gettext/es/LC_MESSAGES/default.po`
- No test file changes.

- [ ] **Step 1: Extract and merge gettext strings**

Run: `mix gettext.extract && mix gettext.merge priv/gettext`
Expected: new `msgid`s for the strings added in Tasks 5–8 appear in `priv/gettext/es/LC_MESSAGES/default.po` (and `errors.po` if applicable) with empty `msgstr`.

- [ ] **Step 2: Fill in Spanish translations**

Edit `priv/gettext/es/LC_MESSAGES/default.po`, providing `msgstr` for each new `msgid`. Suggested translations:

- "This room is password protected" → "Esta sala está protegida por contraseña"
- "Password" → "Contraseña"
- "Enter room" → "Entrar a la sala"
- "Incorrect password. Please try again." → "Contraseña incorrecta. Inténtalo de nuevo."
- "Password (optional)" → "Contraseña (opcional)"
- "Leave blank for a public room" → "Déjalo en blanco para una sala pública"
- "Room password" → "Contraseña de la sala"
- "This room is protected. Update or remove its password." → "Esta sala está protegida. Actualiza o elimina su contraseña."
- "Add a password to protect this room." → "Añade una contraseña para proteger esta sala."
- "New password" → "Nueva contraseña"
- "Remove password" → "Eliminar contraseña"
- "Save" → "Guardar"
- "Saving..." → "Guardando..."
- "Room password updated" → "Contraseña de la sala actualizada"
- "Password must be at least 4 characters" → "La contraseña debe tener al menos 4 caracteres"
- "Password protected" → "Protegida por contraseña"

- [ ] **Step 3: Run the full suite**

Run: `mix test`
Expected: PASS (whole suite green).

- [ ] **Step 4: Commit**

```bash
git add priv/gettext
git commit -m "Add Spanish translations for room password protection"
```

---

## Notes for the implementer

- **Session key type:** session keys are strings; `room.id` is a binary-id string. The `"authorized_rooms"` map uses `room.id` strings as keys.
- **Double room fetch:** `RoomAuth` fetches the room and `RoomLive.Show.mount/3` fetches it again. This is acceptable and keeps responsibilities separated; do not try to thread the room through.
- **Fingerprint rotation:** changing/removing a password changes (or nils) the fingerprint, so other sessions re-prompt on their next visit. This is intended.
- **`empty_values: []`** on `password_changeset` is deliberate — it lets a blank submission clear the password rather than being coerced to "no change".
