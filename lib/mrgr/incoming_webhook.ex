defmodule Mrgr.IncomingWebhook do
  alias Mrgr.Schema.IncomingWebhook, as: Schema
  alias Mrgr.Repo

  alias Mrgr.IncomingWebhook.Query

  @topic "incoming_webhooks"

  @spec topic :: String.t()
  def topic, do: @topic

  @spec create(map()) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    params = inject_installation_id(params)

    %Schema{}
    |> Schema.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, hook} ->
        broadcast_created!(hook)
        {:ok, hook}

      error ->
        error
    end
  end

  @spec all :: [Schema.t()]
  def all do
    Schema
    |> Query.rev_cron()
    |> Repo.all()
  end

  @spec get(integer() | String.t()) :: Schema.t() | nil
  def get(id) do
    Repo.get(Schema, id)
  end

  @spec broadcast_created!(Schema.t()) :: :ok
  def broadcast_created!(hook) do
    Mrgr.PubSub.broadcast(hook, topic(), "created")
  end

  def fire!(hook) do
    Mrgr.Github.Webhook.handle(hook.object, hook.data)
  end

  defp inject_installation_id(%{"installation" => %{"id" => external_id}} = params) do
    case Mrgr.Installation.find_by_external_id(external_id) do
      %Mrgr.Schema.Installation{id: id} ->
        Map.put(params, :installation_id, id)

      nil ->
        params
    end
  end

  defp inject_installation_id(params), do: params

  defmodule Query do
    use Mrgr.Query
  end
end
