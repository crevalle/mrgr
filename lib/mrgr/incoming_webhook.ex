defmodule Mrgr.IncomingWebhook do
  alias Mrgr.Schema.IncomingWebhook, as: Schema
  alias Mrgr.Repo

  alias Mrgr.IncomingWebhook.Query

  @topic "incoming_webhooks"

  @spec topic :: String.t()
  def topic, do: @topic

  @spec create(map()) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    %Schema{}
    |> Schema.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, hook} ->
        broadcast_hook_created!(hook)
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

  @spec broadcast_hook_created!(Schema.t()) :: :ok
  def broadcast_hook_created!(hook) do
    Mrgr.PubSub.broadcast(hook, topic(), "created")
  end

  defmodule Query do
    use Mrgr.Query
  end
end
