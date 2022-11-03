defmodule Mrgr.Repo do
  use Ecto.Repo,
    otp_app: :mrgr,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 50
end
