defmodule Mrgr.RepositorySecurityProfile do
  use Mrgr.PubSub.Event

  alias Mrgr.Schema.RepositorySecurityProfile, as: Schema
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
         {:ok, profile} <- Mrgr.Repo.insert(cs),
         _updated <-
           Mrgr.Repository.set_security_profile_id(repo_ids, profile.installation_id, profile.id) do
      broadcast(profile, @security_profile_created)
      {:ok, profile}
    end
  end

  def update(schema, params) do
    repo_ids = Map.get(params, "repository_ids", [])

    with cs <- Schema.changeset(schema, params),
         {:ok, profile} <- Mrgr.Repo.update(cs),
         _updated <-
           Mrgr.Repository.unset_profile_id(profile.id),
         _updated <-
           Mrgr.Repository.set_security_profile_id(repo_ids, profile.installation_id, profile.id) do
      broadcast(profile, @security_profile_updated)
      {:ok, profile}
    end
  end

  def delete(profile) do
    Mrgr.Repo.delete(profile)
    broadcast(profile, @security_profile_deleted)

    profile
  end

  def broadcast_if_successful({:ok, %{profile: profile}}, event) do
    broadcast(profile, event)

    {:ok, profile}
  end

  def broadcast_if_successful({:ok, profile}, event) do
    broadcast(profile, event)

    {:ok, profile}
  end

  def broadcast_if_successful(error, _event), do: error

  def broadcast(profile, event) do
    topic = Mrgr.PubSub.Topic.installation(profile)
    Mrgr.PubSub.broadcast(profile, topic, event)
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
