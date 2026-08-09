defmodule LivedjWeb.CustomComponents do
  @moduledoc """
  Provides custom UI components.
  """
  use Phoenix.Component

  alias LivedjWeb.CoreComponents
  alias Phoenix.LiveView.JS

  import LivedjWeb.Gettext

  @doc """
  Renders a hover tooltip anchored to a parent `relative group` container.

  Position controls vertical placement (above or below the element).
  Use the `class` attr for horizontal offset and any other per-callsite overrides
  (e.g. `left-1/2 -translate-x-[85%]`, `z-30`, `md:hidden`).
  """
  attr :position, :atom, default: :above, doc: ":above | :below"
  attr :class, :string, default: "left-1/2 -translate-x-1/2"
  slot :inner_block, required: true

  def tooltip(assigns) do
    ~H"""
    <div class={[
      "absolute hidden group-hover:block",
      "whitespace-nowrap rounded-md px-2 py-1",
      "bg-tone-800 dark:bg-tone-200",
      "text-xs text-tone-100 dark:text-tone-900",
      "shadow-md pointer-events-none",
      tooltip_position_class(@position),
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp tooltip_position_class(:above), do: "bottom-full mb-2"
  defp tooltip_position_class(:below), do: "top-full mt-2"

  @doc """
  Renders a button to toggle the application theme
  """
  attr :theme, :string, required: true

  def toggle_theme_button(assigns) do
    ~H"""
    <div
      class="flex items-center gap-4 font-semibold leading-6 text-tone-900"
      phx-hook="Theme"
      id="theme-hook"
    >
      <div class="relative group">
        <a
          class="hover:text-tone-700 cursor-pointer h-5 w-5 leading-3"
          href="#"
          phx-click={JS.dispatch("toggle-theme")}
          tabindex="0"
        >
          <%= if @theme === "dark" do %>
            <CoreComponents.icon
              id="toggle-theme-icon"
              name="hero-sun-solid"
              class="text-black dark:text-white h-5 w-5 hover:dark:text-yellow-500 duration-500"
            />
          <% else %>
            <CoreComponents.icon
              id="toggle-theme-icon"
              name="hero-moon-solid"
              class="text-black dark:text-white h-5 w-5 hover:text-yellow-500 duration-500"
            />
          <% end %>
        </a>
        <.tooltip position={:below} class="left-1/2 -translate-x-[35%] z-30">
          {if @theme === "dark",
            do: "#{gettext("Light")} (T)",
            else: "#{gettext("Dark")} (T)"}
        </.tooltip>
      </div>
    </div>
    """
  end

  @doc """
  Renders the livedj logo
  """
  attr :theme, :string, required: true
  attr :class, :string, default: "w-24 h-10"

  def livedj_logo(assigns) do
    ~H"""
    {PhoenixInlineSvg.Helpers.svg_image(
      LivedjWeb.Endpoint,
      if(@theme === "dark", do: "logo-white", else: "logo-black"),
      class: @class
    )}
    """
  end

  @doc """
  Renders a pill with the application version
  """
  attr :version, :string, required: true

  def version_pill(assigns) do
    ~H"""
    <p class="
      bg-brand/5 dark:bg-brand/100
      text-brand dark:text-white
      rounded-full px-2 font-medium leading-6 text-xs
    ">
      v{@version}
    </p>
    """
  end

  @avatar_colors [
    "bg-tone-500",
    "bg-green-600",
    "bg-blue-600",
    "bg-amber-600",
    "bg-rose-600",
    "bg-violet-600"
  ]

  @doc """
  Renders a circular avatar for the current user with a hover tooltip showing
  the username. Displays the user's avatar image if present, otherwise shows
  colored initials derived from the username.
  """
  attr :user, :any, required: true
  attr :name, :string, default: nil

  def user_avatar(assigns) do
    label =
      if is_binary(assigns.name) and assigns.name != "",
        do: assigns.name,
        else: user_avatar_label(assigns.user)

    assigns =
      assigns
      |> assign(:label, label)
      |> assign(:initials, String.slice(label, 0, 1))
      |> assign(:color, avatar_color(label))
      |> assign(:avatar_url, user_avatar_url(assigns.user))

    ~H"""
    <div class="relative group cursor-default select-none">
      <%= if @avatar_url != "" do %>
        <img
          class="h-7 w-7 rounded-full object-cover"
          src={@avatar_url}
          alt={@label}
        />
      <% else %>
        <span class={[
          "flex h-7 w-7 items-center justify-center rounded-full",
          "text-xs font-semibold uppercase text-tone-100 dark:text-tone-900",
          @color
        ]}>
          {@initials}
        </span>
      <% end %>
      <div class="
        absolute right-0 top-full mt-1.5 z-50
        hidden group-hover:block
        whitespace-nowrap rounded-md px-2 py-1
        bg-tone-800 dark:bg-tone-200
        text-xs text-tone-100 dark:text-tone-900
        shadow-md
      ">
        {@label}
      </div>
    </div>
    """
  end

  defp user_avatar_label(%{username: u}) when is_binary(u) and u != "", do: u

  defp user_avatar_label(%{"username" => u}) when is_binary(u) and u != "",
    do: u

  defp user_avatar_label(_label), do: "?"

  defp user_avatar_url(%{avatar_url: url}) when is_binary(url), do: url
  defp user_avatar_url(_avatar_url), do: ""

  defp avatar_color(label) do
    index = :erlang.phash2(label, length(@avatar_colors))
    Enum.at(@avatar_colors, index)
  end

  attr :id, :string, required: true
  attr :modules, :list, required: true

  attr :module_id, :any,
    default: nil,
    doc: "the function for generating the module id"

  attr :module_click, :any,
    default: nil,
    doc: "the function for handling phx-click on each module"

  attr :module_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each module before calling the :module slots"

  slot :inner_block, required: true

  @doc """
  Renders a grid to display room shortcuts
  """
  def room_grid(assigns) do
    assigns =
      with %{modules: _modules} <- assigns do
        assign(
          assigns,
          module_id: assigns.module_id || fn %{id: id} -> id end
        )
      end

    ~H"""
    <div
      id={@id}
      class="
        grid grid-rows-1 grid-flow-col auto-cols-max
        py-4 w-max gap-4 px-1
      "
    >
      <div
        :for={module <- @modules}
        id={@module_id && @module_id.(module)}
        class="
          group
          h-52 w-40 rounded-lg
          transition duration-300
          bg-tone-50 hover:brightness-90 border-[1px] border-tone-200 dark:border-0
          dark:bg-tone-800 dark:hover:bg-tone-800 dark:hover:brightness-110
        "
      >
        <.link
          phx-click={@module_click && @module_click.(module)}
          href="#"
          class={["relative p-0", @module_click && "hover:cursor-pointer"]}
          tabindex="0"
        >
          <div class="relative leading-6 text-tone-900 hover:text-tone-700">
            {render_slot(@inner_block, module)}
          </div>
        </.link>
      </div>
    </div>
    """
  end
end
