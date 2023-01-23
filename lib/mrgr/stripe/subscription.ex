defmodule Mrgr.Stripe.Subscription do
  alias Mrgr.Schema.StripeSubscription, as: Schema
  alias __MODULE__.Query

  def all do
    Schema
    |> Query.with_installation()
    |> Query.order(desc: :inserted_at)
  end

  defmodule Query do
    use Mrgr.Query

    def with_installation(query) do
      from(q in query,
        join: i in assoc(q, :installation),
        join: a in assoc(i, :account),
        preload: [installation: {i, account: a}]
      )
    end
  end
end
