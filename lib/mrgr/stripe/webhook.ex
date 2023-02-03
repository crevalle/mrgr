defmodule Mrgr.Stripe.Webhook do
  alias Mrgr.Schema.StripeWebhook, as: Schema
  alias __MODULE__.Query

  def receive(params) do
    IO.inspect("*** RECEIVED STRIPE WEBHOOK: #{params["type"]}")

    {:ok, hook} = to_struct(params)

    enqueue_webhook_handling(hook)

    hook
  end

  def to_struct(params) do
    type = params["type"]
    id = params["id"]
    created = params["created"]

    attrs = %{
      external_id: id,
      type: type,
      created: created,
      data: params
    }

    %Schema{}
    |> Schema.changeset(attrs)
    |> Mrgr.Repo.insert()
  end

  def enqueue_webhook_handling(hook) do
    %{id: hook.id}
    |> Mrgr.Worker.StripeWebhook.new()
    |> Oban.insert()
  end

  def get(id) do
    Mrgr.Repo.get(Schema, id)
  end

  def list do
    Schema
    |> Query.order(desc: :created)
  end

  def create_subscription(hook, installation) do
    params = %{
      webhook_id: hook.id,
      installation_id: installation.id,
      node_id: hook.data["data"]["object"]["subscription"]
    }

    %Mrgr.Schema.StripeSubscription{}
    |> Mrgr.Schema.StripeSubscription.changeset(params)
    |> Mrgr.Repo.insert!()
  end

  ### HANDLERS vvv

  @spec fire!(Schema.t()) :: :ok | {:error, atom()}
  def fire!(%{type: "checkout.session.completed", data: data} = hook) do
    with id when is_integer(id) <- client_reference_id(data),
         %Mrgr.Schema.Installation{} = installation <- Mrgr.Installation.find(id) do
      _subscription = create_subscription(hook, installation)

      Mrgr.Installation.activate_subscription!(installation)
    else
      error -> error
    end
  end

  def fire!(_schema) do
    :ok
  end

  defp client_reference_id(%{"data" => %{"object" => %{"client_reference_id" => id}}})
       when is_bitstring(id) do
    String.to_integer(id)
  end

  defp client_reference_id(_), do: {:error, :bad_client_reference}

  defmodule Query do
    use Mrgr.Query
  end
end
