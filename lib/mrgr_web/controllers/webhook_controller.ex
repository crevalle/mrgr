defmodule MrgrWeb.WebhookController do
  use MrgrWeb, :controller

  def github(conn, params) do
    IO.inspect(params, label: "WEBHOOK ***")

    Mrgr.Github.process(params) |> IO.inspect()

    conn
    |> put_status(200)
    |> json(%{yo: "momma"})
  end
end
