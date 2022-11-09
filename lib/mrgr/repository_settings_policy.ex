defmodule Mrgr.RepositorySettingsPolicy do
  use Mrgr.PubSub.Event

  alias Mrgr.Schema.RepositorySettingsPolicy, as: Schema
  alias __MODULE__.Query

  def for_installation(%Mrgr.Schema.Installation{id: id}), do: for_installation(id)

  def for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order(asc: :title)
    |> Mrgr.Repo.all()
  end

  @spec create(map()) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    repo_ids = Map.get(params, "repository_ids", [])

    with cs <- Schema.changeset(%Schema{}, params),
         {:ok, policy} <- Mrgr.Repo.insert(cs),
         _updated <-
           Mrgr.Repository.set_settings_policy_id(repo_ids, policy.installation_id, policy.id) do
      broadcast(policy, @repository_settings_policy_created)
      {:ok, policy}
    end
  end

  def update(schema, params) do
    repo_ids = Map.get(params, "repository_ids", [])

    with cs <- Schema.changeset(schema, params),
         {:ok, policy} <- Mrgr.Repo.update(cs),
         _updated <-
           Mrgr.Repository.unset_policy_id(policy.id),
         _updated <-
           Mrgr.Repository.set_settings_policy_id(repo_ids, policy.installation_id, policy.id) do
      broadcast(policy, @repository_settings_policy_updated)
      {:ok, policy}
    end
  end

  def delete(policy) do
    Mrgr.Repository.unset_policy_id(policy.id)
    Mrgr.Repo.delete(policy)
    broadcast(policy, @repository_settings_policy_deleted)

    policy
  end

  def broadcast(policy, event) do
    topic = Mrgr.PubSub.Topic.installation(policy)
    Mrgr.PubSub.broadcast(policy, topic, event)
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, id) do
      from(q in query,
        where: q.installation_id == ^id
      )
    end
  end
end
