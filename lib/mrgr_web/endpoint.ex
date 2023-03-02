defmodule MrgrWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mrgr

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_mrgr_key",
    signing_salt: "C9p1FCJt"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [timeout: 45_000, connect_info: [session: @session_options]]

  plug :redirect_pending_pr_route

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :mrgr,
    gzip: false,
    only: MrgrWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :mrgr
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug MrgrWeb.Router

  defp redirect_pending_pr_route(%{request_path: "/pending-pull-requests"} = conn, _opts) do
    conn
    |> Phoenix.Controller.redirect(to: "/pull-requests")
    |> Plug.Conn.halt()
  end

  defp redirect_pending_pr_route(conn, _opts), do: conn
end
