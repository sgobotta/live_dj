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
end
