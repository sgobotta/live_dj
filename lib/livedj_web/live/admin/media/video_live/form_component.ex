defmodule LivedjWeb.Admin.Media.VideoLive.FormComponent do
  use LivedjWeb, :live_component

  alias Livedj.Media

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= gettext("Use this form to manage video records in your database.") %>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="video-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label={gettext("Title")} />
        <.input field={@form[:channel]} type="text" label={gettext("Channel")} />
        <.input
          field={@form[:thumbnail_url]}
          type="text"
          label={gettext("Thumbnail url")}
        />
        <.input
          field={@form[:external_id]}
          type="text"
          label={gettext("External id")}
        />
        <.input field={@form[:etag]} type="text" label={gettext("Etag")} />
        <.input
          field={@form[:published_at]}
          type="datetime-local"
          label={gettext("Published at")}
        />
        <:actions>
          <.button phx-disable-with={gettext("Saving...")}>
            <%= gettext("Save Video") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{video: video} = assigns, socket) do
    changeset = Media.change_video(video)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"video" => video_params}, socket) do
    changeset =
      socket.assigns.video
      |> Media.change_video(video_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"video" => video_params}, socket) do
    save_video(socket, socket.assigns.action, video_params)
  end

  defp save_video(socket, :edit, video_params) do
    case Media.update_video(socket.assigns.video, video_params) do
      {:ok, video} ->
        notify_parent({:saved, video})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Video updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_video(socket, :new, video_params) do
    case Media.create_video(video_params) do
      {:ok, video} ->
        notify_parent({:saved, video})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Video created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
