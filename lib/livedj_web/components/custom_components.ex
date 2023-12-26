defmodule LivedjWeb.CustomComponents do
  @moduledoc """
  Provides custom UI components.
  """
  use Phoenix.Component

  alias LivedjWeb.CoreComponents
  alias Phoenix.LiveView.JS

  @doc """
  Renders a button to toggle the application theme
  """
  attr :theme, :string, required: true

  def toggle_theme_button(assigns) do
    ~H"""
    <div
      class="flex items-center gap-4 font-semibold leading-6 text-zinc-900"
      phx-hook="Theme"
      id="theme-hook"
    >
      <a
        class="hover:text-zinc-700 cursor-pointer"
        phx-click={JS.dispatch("toggle-theme")}
      >
        <%= if @theme === "dark" do %>
          <CoreComponents.icon
            id="toggle-theme-icon"
            name="hero-sun-solid"
            class="text-black dark:text-white h-5 w-5"
          />
        <% else %>
          <CoreComponents.icon
            id="toggle-theme-icon"
            name="hero-moon-solid"
            class="text-black dark:text-white h-5 w-5"
          />
        <% end %>
      </a>
    </div>
    """
  end

  @doc """
  Renders the livedj logo
  """
  attr :theme, :string, required: true
  attr :class, :string, default: "w-28 h-18"

  def livedj_logo(assigns) do
    ~H"""
    <%= PhoenixInlineSvg.Helpers.svg_image(
      LivedjWeb.Endpoint,
      if(@theme === "dark", do: "logo-white", else: "logo-black"),
      class: @class
    ) %>
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
      rounded-full px-2 font-medium leading-6
    ">
      v<%= @version %>
    </p>
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
      with %{modules: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(
          assigns,
          module_id: assigns.module_id || fn {id, _item} -> id end
        )
      end

    ~H"""
    <div
      id={@id}
      class="
        grid grid-rows-2 grid-flow-col
        my-4 py-4 w-full gap-4
        overflow-x-scroll
      "
    >
      <div
        :for={module <- @modules}
        id={@module_id && @module_id.(module)}
        class="
          group
          h-52 w-40 rounded-lg
          bg-zinc-50 hover:bg-zinc-200 border-[1px] border-zinc-200 dark:border-0
          dark:bg-zinc-800 dark:hover:bg-zinc-700
        "
      >
        <div
          phx-click={@module_click && @module_click.(module)}
          class={["relative p-0", @module_click && "hover:cursor-pointer"]}
        >
          <div class="relative leading-6 text-zinc-900 hover:text-zinc-700">
            <%= render_slot(@inner_block, module) %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
