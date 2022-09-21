defmodule MrgrWeb.Router do
  use MrgrWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MrgrWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :authenticate_user
  end

  pipeline :authenticate do
    plug :require_user
  end

  pipeline :with_current_installation do
    plug :notify_missing_installation
  end

  pipeline :admin do
    plug :require_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MrgrWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/sign-in", AuthController, :new
  end

  scope "/auth", MrgrWeb do
    pipe_through :browser

    # post "/sign-in", AuthController, :create
    delete "/sign-out", AuthController, :delete
    get "/sign-out", AuthController, :delete

    get "/github", AuthController, :github
    get "/github/callback", AuthController, :callback
  end

  scope "/", MrgrWeb do
    pipe_through [:browser, :authenticate]

    get "/onboarding", OnboardingController, :index
    get "/onboarding/installation-complete", OnboardingController, :installation_complete
  end

  scope "/", MrgrWeb do
    pipe_through [:browser, :authenticate, :with_current_installation]

    get "/pending-merges", PendingMergeController, :index
    get "/pending-merges/:id", PendingMergeController, :show
    resources "/file-change-alerts", FileChangeAlertController, only: [:index, :edit]

    resources "/repositories", RepositoryController, only: [:index]
  end

  scope "/", MrgrWeb.Live do
    live_session :default, on_mount: [MrgrWeb.Plug.Auth, MrgrWeb.Locale] do
    end
  end

  scope "/webhooks", MrgrWeb do
    pipe_through :api

    post "/incoming/github", WebhookController, :github
  end

  scope "/admin", MrgrWeb.Admin, as: :admin do
    pipe_through [:browser, :authenticate, :admin]

    live "/incoming-webhooks", Live.IncomingWebhook, :index, as: :incoming_webhook
    live "/incoming-webhooks/:id", Live.IncomingWebhookShow, :show, as: :incoming_webhook

    live "/installations", Live.Installation, :index, as: :installation
    live "/installations/:id", Live.InstallationShow, :show, as: :installation

    live "/github_api_requests", Live.GithubAPIRequest, :index, as: :github_api_request

    live "/users", Live.User, :index, as: :user
    live "/users/:id", Live.UserShow, :show, as: :user

    live "/waiting-list-signups", Live.WaitingListSignup, :index, as: :waiting_list_signup
  end

  # Other scopes may use custom stacks.
  # scope "/api", MrgrWeb do
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
      live_dashboard "/dashboard", metrics: MrgrWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
