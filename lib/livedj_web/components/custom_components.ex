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
    <span class={[
      "absolute hidden group-hover:block",
      "whitespace-nowrap rounded-md px-1 py-1",
      "bg-tone-800 dark:bg-tone-200",
      "text-xs text-tone-100 dark:text-tone-900",
      "shadow-md pointer-events-none",
      tooltip_position_class(@position),
      @class
    ]}>
      {render_slot(@inner_block)}
    </span>
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
          class="hover:text-tone-700 cursor-pointer h-5 w-5 leading-3 inline-flex items-center justify-center rounded focus:outline-none focus-ignite"
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
  attr :class, :string, default: "h-7 w-7 text-xs"
  attr :tooltip, :boolean, default: true

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
          class={["rounded-full object-cover", @class]}
          src={@avatar_url}
          alt={@label}
        />
      <% else %>
        <span class={[
          "flex items-center justify-center rounded-full",
          "font-semibold uppercase text-tone-100 dark:text-tone-900",
          @class,
          @color
        ]}>
          {@initials}
        </span>
      <% end %>
      <div
        :if={@tooltip}
        class="
        absolute right-0 top-full mt-1.5 z-50
        hidden group-hover:block
        whitespace-nowrap rounded-md px-2 py-1
        bg-tone-800 dark:bg-tone-200
        text-xs text-tone-100 dark:text-tone-900
        shadow-md
      "
      >
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

  @doc """
  Renders a labeled on/off switch for a boolean preference.

  Purely presentational: the initial visual state always renders off. A
  `phx-hook`'d client-side owner is expected to correct the visual state on
  mount (from wherever the preference is actually persisted) and to own all
  further state changes, since this component is not wired to any
  `phx-click` or server assign.
  """
  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :description, :string, default: nil
  attr :hook, :string, required: true, doc: "the phx-hook that owns this switch"

  def toggle_switch(assigns) do
    ~H"""
    <div class="flex items-center justify-between gap-4">
      <div>
        <p class="text-sm font-semibold text-tone-700 dark:text-tone-300">
          {@label}
        </p>
        <p
          :if={@description}
          class="text-xs text-tone-500 dark:text-tone-400 mt-0.5"
        >
          {@description}
        </p>
      </div>
      <button
        id={@id}
        type="button"
        role="switch"
        aria-checked="false"
        phx-hook={@hook}
        phx-update="ignore"
        class="
          relative inline-flex h-6 w-11 shrink-0 items-center rounded-full
          bg-tone-300 dark:bg-tone-600 transition-colors duration-300 ease-in-out
          focus:outline-none focus-ignite
        "
      >
        <span
          aria-hidden="true"
          class="
            pointer-events-none inline-block h-4 w-4 translate-x-1 rounded-full
            bg-white shadow-md transition-transform duration-300 ease-in-out
          "
        />
      </button>
    </div>
    """
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
        grid gap-4 py-4
        grid-cols-2 sm:grid-cols-3
      "
    >
      <div
        :for={{module, rank} <- Enum.with_index(@modules)}
        id={@module_id && @module_id.(module)}
        phx-hook="RoomGridReorder"
        data-rank={rank}
        class="
          group rounded-xl
          bg-tone-50 dark:bg-tone-800
          border border-tone-200 dark:border-transparent
          shadow-sm hover:shadow-lg
          transition duration-300
          hover:-translate-y-1 hover:brightness-[0.98] dark:hover:brightness-110
        "
      >
        <.link
          phx-click={@module_click && @module_click.(module)}
          href="#"
          class={[
            "block rounded-xl p-2 focus:outline-none focus-ignite",
            @module_click && "hover:cursor-pointer"
          ]}
          tabindex="0"
        >
          <div class="relative leading-6 text-tone-900 dark:text-tone-100">
            {render_slot(@inner_block, module)}
          </div>
        </.link>
      </div>
    </div>
    """
  end
end
