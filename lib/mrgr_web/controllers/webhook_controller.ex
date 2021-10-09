defmodule MrgrWeb.WebhookController do
  use MrgrWeb, :controller

  def github(conn, params) do
    IO.inspect(conn.req_headers, label: "REQUEST HEADERS:")
    IO.inspect(conn.resp_headers, label: "RESPONSE HEADERS:")
    IO.inspect(params, label: "WEBHOOK ***")

    Mrgr.Github.Webhook.handle(params)

    conn
    |> put_status(200)
    |> json(%{yo: "momma"})
  end
end
