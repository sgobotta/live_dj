defmodule LivedjWeb.Router do
  use LivedjWeb, :router

  import LivedjWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LivedjWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LivedjWeb do
    pipe_through :browser

    get "/", PageController, :home

    live_session :sessions,
      layout: {LivedjWeb.Layouts, :session},
      on_mount: [{LivedjWeb.UserAuth, :mount_current_user}],
      root_layout: {LivedjWeb.Layouts, :root_session} do
      scope "/sessions", Sessions do
        live "/rooms", RoomLive.Index, :index
        live "/rooms/:id", RoomLive.Show, :show
      end
    end

    scope "/admin" do
      scope "/sessions", Admin.Sessions do
        pipe_through [:require_authenticated_user]

        live "/rooms", RoomLive.Index, :index
        live "/rooms/new", RoomLive.Index, :new
        live "/rooms/:id/edit", RoomLive.Index, :edit

        live "/rooms/:id", RoomLive.Show, :show
        live "/rooms/:id/show/edit", RoomLive.Show, :edit
      end

      scope "/media", Admin.Media do
        pipe_through [:require_authenticated_user]

        live "/videos", VideoLive.Index, :index
        live "/videos/new", VideoLive.Index, :new
        live "/videos/:id/edit", VideoLive.Index, :edit

        live "/videos/:id", VideoLive.Show, :show
        live "/videos/:id/show/edit", VideoLive.Show, :edit
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", LivedjWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:livedj, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LivedjWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LivedjWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LivedjWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", LivedjWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{LivedjWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit

      live "/users/settings/confirm_email/:token",
           UserSettingsLive,
           :confirm_email
    end
  end

  scope "/", LivedjWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{LivedjWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
