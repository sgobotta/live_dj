defmodule LivedjWeb.ListComponent do
  @moduledoc false
  use LivedjWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 py-4 rounded-lg">
      <div class="space-y-5 mx-auto max-w-7xl px-4 space-y-4">
        <.header>
          <%= @list_name %>
          <.simple_form
            for={@form}
            phx-change="validate"
            phx-submit="save"
            phx-target={@myself}
            class="flex"
          >
            <div class="flex flex-row">
              <.input field={@form[:name]} type="text" />
            </div>
            <:actions>
              <.button class="align-middle ml-2">
                <.icon name="hero-plus" />
              </.button>
            </:actions>
          </.simple_form>
        </.header>
        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id}>
          <div
            :for={item <- @list}
            id={"#{@id}-#{item.id}"}
            data-id={item.id}
            class="
              bg-white my-2 rounded-xl border-gray-300 border-2
              drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0
              drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0
            "
          >
            <div class="flex drag-ghost:opacity-0 gap-y-2">
              <button type="button" class="w-10">
                <.icon
                  name="hero-check-circle"
                  class={[
                    "w-7 h-7",
                    if(item.status == :completed,
                      do: "bg-green-600",
                      else: "bg-gray-300"
                    )
                  ]}
                />
              </button>
              <div class="flex-auto block text-sm leading-6 text-zinc-900">
                <%= item.name %>
              </div>
              <button type="button" class="w-10 -mt-1 flex-none">
                <.icon name="hero-x-mark" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("reposition", params, socket) do
    # Put your logic here to deal with the changes to the list order
    # and persist the data
    {:noreply, socket}
  end
end
