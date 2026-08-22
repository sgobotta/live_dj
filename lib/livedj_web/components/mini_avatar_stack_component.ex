defmodule LivedjWeb.MiniAvatarStackComponent do
  @moduledoc """
  Overlapping mini avatars for room members, with overflow badge support.
  """
  use Phoenix.Component

  alias LivedjWeb.CustomComponents

  import LivedjWeb.Gettext

  @max_visible 10

  @doc """
  Renders a row of overlapping mini avatars for room members.

  Shows up to `max_visible` slots. When there are more members than that,
  the last slot is a `+N` badge where N is the number of members not shown
  as individual avatars.

  When `current_user_id` is set, the matching member is sorted first (so
  they're never the one hidden behind the overflow badge) and hovering the
  stack opens a panel listing every member, with the current user's row
  called out.
  """
  attr :id, :string, required: true
  attr :users, :list, required: true
  attr :max_visible, :integer, default: @max_visible
  attr :size, :atom, values: [:sm, :md], default: :sm
  attr :class, :string, default: nil
  attr :current_user_id, :string, default: nil

  def mini_avatar_stack(assigns) do
    users = reorder_current_user_first(assigns.users, assigns.current_user_id)

    {shown_users, overflow} = partition_avatar_users(users, assigns.max_visible)

    assigns =
      assigns
      |> assign(:users, users)
      |> assign(:shown_users, shown_users)
      |> assign(:overflow, overflow)
      |> assign(:dims, avatar_size_dims(assigns.size))

    ~H"""
    <div
      :if={length(@users) > 0}
      class={["relative group flex items-center", @dims.stack_height, @class]}
    >
      <div
        :for={{user, index} <- Enum.with_index(@shown_users)}
        class={[
          "relative shrink-0 rounded-full ring-2 ring-zinc-50 dark:ring-zinc-800",
          @dims.avatar,
          index > 0 && @dims.overlap
        ]}
        style={"z-index: #{index + 1}"}
      >
        <CustomComponents.avatar
          id={"#{@id}-avatar-#{index}"}
          label={avatar_label(user)}
          avatar_url={avatar_url(user)}
          class={"h-full w-full #{@dims.text}"}
        />
      </div>
      <div
        :if={@overflow > 0}
        class={[
          "relative shrink-0 flex items-center justify-center",
          @dims.avatar,
          @dims.overlap,
          @dims.text,
          "rounded-full ring-2 ring-zinc-50 dark:ring-zinc-800",
          "bg-zinc-300 dark:bg-zinc-600",
          "font-semibold text-zinc-800 dark:text-zinc-100"
        ]}
        style={"z-index: #{length(@shown_users) + 1}"}
      >
        +{@overflow}
      </div>
      <div
        :if={@current_user_id}
        class="
          invisible absolute right-0 top-full z-50 pt-2 opacity-0
          transition-opacity duration-150
          group-hover:visible group-hover:opacity-100
        "
      >
        <div class="
          w-56 max-h-72 overflow-y-auto rounded-lg py-1.5 shadow-lg
          bg-tone-50 dark:bg-tone-800
          border border-tone-200 dark:border-tone-700
        ">
          <div
            :for={{user, index} <- Enum.with_index(@users)}
            class="flex items-center gap-2 px-3 py-1.5"
          >
            <CustomComponents.avatar
              id={"#{@id}-dialog-avatar-#{index}"}
              label={avatar_label(user)}
              avatar_url={avatar_url(user)}
              class="h-6 w-6 text-[0.6rem] shrink-0"
            />
            <span class={[
              "truncate text-sm text-tone-900 dark:text-tone-100 cursor-pointer",
              current_user?(user, @current_user_id) && "font-semibold"
            ]}>
              {avatar_label(user)}
            </span>
            <span
              :if={current_user?(user, @current_user_id)}
              class="h-1.5 w-1.5 shrink-0 rounded-full bg-brand"
              aria-hidden="true"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp avatar_size_dims(:sm) do
    %{
      stack_height: "h-5",
      avatar: "h-5 w-5",
      overlap: "-ml-1.5",
      text: "text-[0.5rem]"
    }
  end

  defp avatar_size_dims(:md) do
    %{stack_height: "h-7", avatar: "h-7 w-7", overlap: "-ml-2", text: "text-xs"}
  end

  @doc """
  Renders example mini avatar stacks for common member counts.
  """
  def mini_avatar_stack_examples(assigns) do
    ~H"""
    <div class="flex flex-col gap-1 px-2 mb-2">
      <%= for count <- [0, 1, 2, 3, 7, 8, 16] do %>
        <.mini_avatar_stack
          id={"mini-avatar-stack-demo-#{count}"}
          users={demo_avatar_users(count)}
        />
      <% end %>
    </div>
    """
  end

  defp partition_avatar_users(users, max_visible) when max_visible > 0 do
    total = length(users)

    cond do
      total == 0 ->
        {[], 0}

      total > max_visible ->
        shown = Enum.take(users, max_visible - 1)
        {shown, total - length(shown)}

      true ->
        {users, 0}
    end
  end

  defp demo_avatar_users(0), do: []

  defp demo_avatar_users(count) when count > 0 do
    Enum.map(1..count, fn index ->
      %{username: "user#{index}", avatar_url: nil}
    end)
  end

  defp avatar_url(%{avatar_url: url}) when is_binary(url), do: url
  defp avatar_url(%{"avatar_url" => url}) when is_binary(url), do: url
  defp avatar_url(_user), do: ""

  defp avatar_label(%{username: username}) when is_binary(username),
    do: username

  defp avatar_label(%{"username" => username}) when is_binary(username),
    do: username

  defp avatar_label(%{email: email}) when is_binary(email), do: email
  defp avatar_label(%{"email" => email}) when is_binary(email), do: email
  defp avatar_label(_user), do: gettext("User")

  defp avatar_id(%{id: id}), do: id
  defp avatar_id(%{"id" => id}), do: id
  defp avatar_id(_user), do: nil

  defp current_user?(user, current_user_id) do
    current_user_id != nil and avatar_id(user) == current_user_id
  end

  defp reorder_current_user_first(users, nil), do: users

  defp reorder_current_user_first(users, current_user_id) do
    Enum.sort_by(users, fn user ->
      if current_user?(user, current_user_id), do: 0, else: 1
    end)
  end
end
