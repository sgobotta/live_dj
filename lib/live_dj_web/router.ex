defmodule LiveDjWeb.Router do
  use LiveDjWeb, :router

  import LiveDjWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LiveDjWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveDjWeb.Room do
    pipe_through :browser

    # live "/", PageLive, :index
    live "/", NewLive, :new
    live "/room/:slug", ShowLive, :show
  end

  scope "/room" do
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveDjWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: LiveDjWeb.Telemetry
    end
  end

  ## Authentication routes

  scope "/", LiveDjWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", LiveDjWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :index
    get "/users/settings/account", UserSettingsController, :edit
    put "/users/settings/update_username", UserSettingsController, :update_username
    put "/users/settings/update_password", UserSettingsController, :update_password
    put "/users/settings/update_email", UserSettingsController, :update_email
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", LiveDjWeb do
    pipe_through [:browser]

    get "/donations", DonationsController, :index
    get "/donations/thanks", DonationsController, :thanks
    get "/donations/:donation_id", DonationsController, :new
    get "/policies/:policy", PoliciesController, :index
    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end
end
