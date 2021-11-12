defmodule MrgrWeb.Router do
  use MrgrWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MrgrWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_user
  end

  pipeline :authenticate do
    plug :require_user
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
  end

  scope "/auth", MrgrWeb do
    pipe_through :browser

    # get "/sign-in", AuthController, :new
    # post "/sign-in", AuthController, :create
    delete "/sign-out", AuthController, :delete

    get "/github", AuthController, :github
    get "/github/callback", AuthController, :callback
  end

  scope "/", MrgrWeb do
    pipe_through [:browser, :authenticate]

    live_session :default, on_mount: [MrgrWeb.Plug.Auth, MrgrWeb.Locale] do
      live "/pending-merges", PendingMergeLive, :index
    end

    resources "/repositories", RepositoryController, only: [:index]
  end

  scope "/webhooks", MrgrWeb do
    pipe_through :api

    post "/incoming/github", WebhookController, :github
  end

  scope "/admin", MrgrWeb.Admin, as: :admin do
    pipe_through [:browser, :authenticate, :admin]

    live "/incoming-webhooks", Live.IncomingWebhook, :index, as: :incoming_webhook
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
