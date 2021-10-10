defmodule MrgrWeb.WebhookController do
  use MrgrWeb, :controller

  def github(conn, params) do
    # IO.inspect(conn.req_headers, label: "REQUEST HEADERS:")

    # Request Headers
    # [
    # {"accept", "*/*"},
    # {"accept-encoding", "gzip, deflate"},
    # {"connect-time", "0"},
    # {"connection", "close"},
    # {"content-length", "21161"},
    # {"content-type", "application/json"},
    # {"host", "smee.io"},
    # {"timestamp", "1633884050645"},
    # {"total-route-time", "0"},
    # {"user-agent", "GitHub-Hookshot/9b4b05d"},
    # {"via", "1.1 vegur"},
    # {"x-forwarded-for", "140.82.115.114"},
    # {"x-forwarded-port", "443"},
    # {"x-forwarded-proto", "https"},
    # {"x-github-delivery", "d388eb80-29e8-11ec-8c53-eeb8b1dc6d61"},
    # {"x-github-event", "pull_request"},
    # {"x-github-hook-id", "319629804"},
    # {"x-github-hook-installation-target-id", "139973"},
    # {"x-github-hook-installation-target-type", "integration"},
    # {"x-request-id", "9964a276-55dc-4e56-b6db-bf0fc58cea59"},
    # {"x-request-start", "1633884050644"}
    # ]
    #
    # IO.inspect(params, label: "WEBHOOK ***")

    obj = fetch_object(conn.req_headers)
    action = params["action"]
    IO.inspect("#{action} for #{obj}", label: "PROCESSING ***")

    Mrgr.Github.Webhook.handle(obj, params)

    conn
    |> put_status(200)
    |> json(%{yo: "momma"})
  end

  def fetch_object(headers) do
    key = "x-github-event"
    fetch_header_value(headers, key)
  end

  def fetch_header_value(headers, key) do
    {_match, obj} = Enum.find(headers, fn {header, _value} -> header == key end)
    obj
  end
end
