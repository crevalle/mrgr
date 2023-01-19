defmodule Mrgr.Repo do
  use Ecto.Repo,
    otp_app: :mrgr,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 20

  def count(query) do
    aggregate(query, :count, :id)
  end
end
