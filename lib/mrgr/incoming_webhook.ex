defmodule Mrgr.IncomingWebhook do
  use Mrgr.PubSub.Event

  alias Mrgr.Schema.IncomingWebhook, as: Schema
  alias Mrgr.Repo

  alias Mrgr.IncomingWebhook.Query

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

  def paged(page \\ []) do
    Schema
    |> Query.rev_cron()
    |> Query.with_installation()
    |> Mrgr.Repo.paginate(page)
  end

  @spec get(integer() | String.t()) :: Schema.t() | nil
  def get(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_installation()
    |> Repo.one()
  end

  def for_installation(id) do
    Schema
    |> Query.for_installation(id)
    |> Query.rev_cron()
    |> Query.limit(10)
    |> Repo.all()
  end

  @spec broadcast_created!(Schema.t()) :: :ok
  def broadcast_created!(hook) do
    Mrgr.PubSub.broadcast(hook, Mrgr.PubSub.Topic.admin(), @incoming_webhook_created)
  end

  def fire!(hook) do
    Mrgr.Github.Webhook.handle(hook.object, hook.data)
  end

  defp inject_installation_id(%{data: %{"installation" => %{"id" => external_id}}} = params) do
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

    def with_installation(query) do
      from(q in query,
        left_join: i in assoc(q, :installation),
        left_join: a in assoc(i, :account),
        preload: [installation: {i, account: a}]
      )
    end

    def for_installation(query, installation_id) do
      from(q in query,
        where: q.installation_id == ^installation_id
      )
    end
  end
end
