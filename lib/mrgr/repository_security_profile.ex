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

  def create(params) do
    %Schema{}
    |> Schema.changeset(params)
    |> Mrgr.Repo.insert()
    |> broadcast_if_successful(@security_profile_created)
  end

  def update(schema, params) do
    schema
    |> Schema.changeset(params)
    |> Mrgr.Repo.update()
    |> broadcast_if_successful(@security_profile_updated)
  end

  def delete(profile) do
    Mrgr.Repo.delete(profile)
    broadcast(profile, @security_profile_deleted)

    profile
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
