defmodule Mrgr.Label do
  use Mrgr.PubSub.Event

  alias __MODULE__.Query
  alias Mrgr.Schema.Label, as: Schema

  def for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.preload_repositories()
    |> Query.order_by_insensitive(asc: :name)
    |> Mrgr.Repo.all()
  end

  def create(params) do
    with cs <- Schema.changeset(%Schema{}, params),
         {:ok, label} <- Mrgr.Repo.insert(cs) do
      Mrgr.PubSub.broadcast_to_installation(label, @label_created)
      {:ok, label}
    end
  end

  def update(schema, params) do
    with cs <- Schema.changeset(schema, params),
         {:ok, label} <- Mrgr.Repo.update(cs) do
      Mrgr.PubSub.broadcast_to_installation(label, @label_updated)
      {:ok, label}
    end
  end

  def delete(label) do
    Mrgr.Repo.delete(label)

    Mrgr.PubSub.broadcast_to_installation(label, @label_deleted)
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, id) do
      from(q in query,
        where: q.installation_id == ^id
      )
    end

    ### preloads both associations off the label, so
    # you *can't* do label_repository.repository
    def preload_repositories(query) do
      from(q in query,
        join: lr in assoc(q, :label_repositories),
        join: r in assoc(q, :repositories),
        preload: [label_repositories: lr, repositories: r]
      )
    end
  end
end
