defmodule MrgrWeb.Router do
  use MrgrWeb, :router
  import Oban.Web.Router
  import Phoenix.LiveDashboard.Router

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

  pipeline :require_installation do
    plug :redirect_missing_installation_to_onboarding
  end

  pipeline :redirect_onboarded_users do
    plug :redirect_onboarded_users_to_dashboard
  end

  pipeline :skip_auth_for_logged_in_folks do
    plug :redirect_logged_in_to_dashboard
  end

  pipeline :admin do
    plug :require_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MrgrWeb do
    pipe_through :browser
  end

  scope "/", MrgrWeb do
    pipe_through [:browser, :skip_auth_for_logged_in_folks]

    # sign in at root
    get "/", AuthController, :new
    get "/sign-in", AuthController, :new
    get "/sign-up", AuthController, :sign_up
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

    live "/onboarding", OnboardingLive, :index
    live "/profile", ProfileLive, :show
    live "/account", AccountLive, :show
  end

  scope "/", MrgrWeb do
    pipe_through [:browser, :authenticate, :require_installation]

    live "/pull-requests", PullRequestDashboardLive, :index
    live "/pull-requests/:tab", PullRequestDashboardLive, :show
    live "/pull-requests/:tab/:pull_request_id/:attr", PullRequestDashboardLive, :detail
    live "/high-impact-files", HighImpactFileLive, :index
    live "/changelog", ChangelogLive, :index

    live "/checklists", Live.Checklist, :index, as: :checklist

    live "/repositories", RepositoryListLive, :index
    live "/labels", LabelListLive, :index
  end

  scope "/", MrgrWeb.Live do
    live_session :default, on_mount: [MrgrWeb.Plug.Auth, MrgrWeb.Locale] do
    end
  end

  scope "/webhooks", MrgrWeb do
    pipe_through :api

    post "/incoming/github", WebhookController, :github
    post "/incoming/stripe", WebhookController, :stripe
  end

  scope "/admin", MrgrWeb.Admin, as: :admin do
    pipe_through [:browser, :authenticate, :admin]

    oban_dashboard("/oban")

    live_dashboard "/dashboard",
      metrics: MrgrWeb.Telemetry,
      metrics_history: {MrgrWeb.TelemetryStorage, :metrics_history, []}

    live "/incoming-webhooks", Live.IncomingWebhook, :index, as: :incoming_webhook
    live "/incoming-webhooks/:id", Live.IncomingWebhookShow, :show, as: :incoming_webhook

    live "/stripe-webhooks", Live.StripeWebhook, :index, as: :stripe_webhook
    live "/stripe-webhooks/:id", Live.StripeWebhookShow, :show, as: :stripe_webhook

    live "/installations", Live.Installation, :index, as: :installation
    live "/installations/:id", Live.InstallationShow, :show, as: :installation
    live "/installations/:id/pull-requests", Live.PullRequestList, :index, as: :pull_request

    live "/subscriptions", Live.Subscription, :index, as: :subscription

    live "/github_api_requests", Live.GithubAPIRequest, :index, as: :github_api_request

    live "/users", Live.User, :index, as: :user
    live "/users/:id", Live.UserShow, :show, as: :user

    live "/waiting-list-signups", Live.WaitingListSignup, :index, as: :waiting_list_signup
  end

  # Other scopes may use custom stacks.
  # scope "/api", MrgrWeb do
  #   pipe_through :api
  # end

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
