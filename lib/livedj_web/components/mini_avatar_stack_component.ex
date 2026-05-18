defmodule LivedjWeb.MiniAvatarStackComponent do
  @moduledoc """
  Overlapping mini avatars for room members, with overflow badge support.
  """
  use Phoenix.Component

  import LivedjWeb.Gettext

  @max_visible 10

  @doc """
  Renders a row of overlapping mini avatars for room members.

  Shows up to 8 slots. When there are more than 8 users, the last slot is a
  `+N` badge where N is the number of users not shown as individual avatars.
  """
  attr :users, :list, required: true
  attr :max_visible, :integer, default: @max_visible
  attr :class, :string, default: nil

  def mini_avatar_stack(assigns) do
    {shown_users, overflow} =
      partition_avatar_users(assigns.users, assigns.max_visible)

    assigns =
      assigns
      |> assign(:shown_users, shown_users)
      |> assign(:overflow, overflow)

    ~H"""
    <div :if={length(@users) > 0} class={["flex items-center h-5", @class]}>
      <div
        :for={{user, index} <- Enum.with_index(@shown_users)}
        class={[
          "relative shrink-0 h-5 w-5 rounded-full ring-2 ring-zinc-50 dark:ring-zinc-800",
          index > 0 && "-ml-1.5"
        ]}
        style={"z-index: #{index + 1}"}
      >
        <%= if avatar_url(user) != "" do %>
          <img
            class="h-5 w-5 rounded-full object-cover"
            src={avatar_url(user)}
            alt={avatar_label(user)}
          />
        <% else %>
          <span class={[
            "flex h-5 w-5 items-center justify-center rounded-full",
            "text-[0.5rem] font-semibold uppercase",
            "text-zinc-100 dark:text-zinc-900",
            avatar_color_class(user)
          ]}>
            <%= avatar_initials(user) %>
          </span>
        <% end %>
      </div>
      <div
        :if={@overflow > 0}
        class="
          relative shrink-0 -ml-1.5 flex h-5 w-5 items-center justify-center
          rounded-full ring-2 ring-zinc-50 dark:ring-zinc-800
          bg-zinc-300 dark:bg-zinc-600
          text-[0.5rem] font-semibold
          text-zinc-800 dark:text-zinc-100
        "
        style={"z-index: #{length(@shown_users) + 1}"}
      >
        +<%= @overflow %>
      </div>
    </div>
    """
  end

  @doc """
  Renders example mini avatar stacks for common member counts.
  """
  def mini_avatar_stack_examples(assigns) do
    ~H"""
    <div class="flex flex-col gap-1 px-2 mb-2">
      <%= for count <- [0, 1, 2, 3, 7, 8, 16] do %>
        <.mini_avatar_stack users={demo_avatar_users(count)} />
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
      %{email: "user#{index}@example.com", avatar_url: nil}
    end)
  end

  defp avatar_url(%{avatar_url: url}) when is_binary(url), do: url
  defp avatar_url(%{"avatar_url" => url}) when is_binary(url), do: url
  defp avatar_url(_user), do: ""

  defp avatar_label(%{email: email}) when is_binary(email), do: email
  defp avatar_label(%{"email" => email}) when is_binary(email), do: email
  defp avatar_label(_user), do: gettext("User")

  defp avatar_initials(user) do
    user
    |> avatar_label()
    |> String.slice(0, 1)
  end

  @avatar_colors [
    "bg-zinc-500",
    "bg-green-600",
    "bg-blue-600",
    "bg-amber-600",
    "bg-rose-600",
    "bg-violet-600"
  ]

  defp avatar_color_class(user) do
    label = avatar_label(user)
    index = :erlang.phash2(label, length(@avatar_colors))
    Enum.at(@avatar_colors, index)
  end
end
