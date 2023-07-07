defmodule Mrgr.Label do
  use Mrgr.PubSub.Event

  alias __MODULE__.Query
  alias Mrgr.Schema.Label, as: Schema

  def for_installation(%{id: id}), do: for_installation(id)

  def for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.with_repo_count()
    |> Query.order_by_insensitive(asc: :name)
    |> Mrgr.Repo.all()
  end

  def list_for_user(%{current_installation_id: installation_id}) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order_by_insensitive(asc: :name)
    |> Mrgr.Repo.all()
  end

  def tabs_for_user(user) do
    Schema
    |> Query.tabs_for_user(user.id)
    |> Mrgr.Repo.all()
  end

  def find_association(lr_id) do
    Mrgr.Schema.LabelRepository
    |> Query.by_id(lr_id)
    |> Query.with_lr_assocs()
    |> Mrgr.Repo.one()
  end

  def find_association_by_node_id(node_id) do
    Mrgr.Schema.LabelRepository
    |> Query.by_node_id(node_id)
    |> Query.with_lr_assocs()
    |> Mrgr.Repo.one()
  end

  def repo_ids(label) do
    Mrgr.Schema.LabelRepository
    |> Query.where(label_id: label.id)
    |> Query.select_repo_ids()
    |> Mrgr.Repo.all()
  end

  @spec update_from_webhook(Mrgr.Schema.LabelRepository.t(), map, map) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def update_from_webhook(lr, params, changes) do
    with true <- has_several_repos?(lr.label),
         true <- changing_name?(changes) do
      fork_label(params, lr)
    else
      false ->
        lr.label
        |> Schema.changeset(params)
        |> Mrgr.Repo.update()
        |> case do
          {:ok, label} ->
            Mrgr.PubSub.broadcast_to_installation(label, @label_updated)
            {:ok, label}

          error ->
            error
        end
    end
  end

  defp changing_name?(%{"name" => _yep}), do: true
  defp changing_name?(_nope), do: false

  defp has_several_repos?(label) do
    repo_count(label) > 1
  end

  def repo_count(label) do
    Mrgr.Schema.LabelRepository
    |> Query.where(label_id: label.id)
    |> Mrgr.Repo.aggregate(:count, :id)
  end

  @spec fork_label(map, Mrgr.Schema.LabelRepository.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def fork_label(params, lr) do
    repo = lr.repository

    Mrgr.Repo.delete(lr)

    create_for_repo(params, repo)
  end

  # will choke on excessive label_repositories
  def delete_locally(label) do
    Enum.map(label.label_repositories, &Mrgr.Repo.delete/1)

    Mrgr.Repo.delete(label)
    Mrgr.PubSub.broadcast_to_installation(label, @label_deleted)
  end

  def delete_from_webhook(%{label: label} = lr) do
    case has_several_repos?(label) do
      true ->
        Mrgr.Repo.delete(lr)

      false ->
        # delete takes care of the associations
        label = %{label | label_repositories: [lr]}
        delete_locally(label)
    end
  end

  def find_or_create_for_repo(params, repo) do
    case find_by_name_for_repo(params["name"], repo) do
      %Schema{} = label ->
        label

      nil ->
        case find_by_name_for_installation(params["name"], repo.installation_id) do
          nil -> create_for_repo(params, repo)
          label -> associate_with_repo(label.id, repo.id, params["node_id"])
        end
    end
  end

  # for associating to a single repo, not many at once a la the form
  def create_for_repo(params, repo) do
    params = Map.put(params, "installation_id", repo.installation_id)

    with cs <- Schema.changeset(%Schema{}, params),
         {:ok, label} <- Mrgr.Repo.insert(cs),
         label_repository <- associate_with_repo(label.id, repo.id, params["node_id"]) do
      Mrgr.PubSub.broadcast_to_installation(label, @label_created)

      {:ok, %{label | label_repositories: [label_repository]}}
    end
  end

  def associate_with_repo(label_id, repo_id, node_id \\ nil) do
    %Mrgr.Schema.LabelRepository{}
    |> Mrgr.Schema.LabelRepository.changeset(%{
      label_id: label_id,
      repository_id: repo_id,
      node_id: node_id
    })
    |> Mrgr.Repo.insert!()
  end

  def find_by_name_for_repo(name, repo) do
    Schema
    |> Query.by_name(name)
    |> Query.for_repository(repo)
    |> Mrgr.Repo.one()
  end

  def find_by_name_for_installation(name, installation_id) do
    Schema
    |> Query.by_name(name)
    |> Query.for_installation(installation_id)
    |> Mrgr.Repo.one()
  end

  def find_with_label_repositories(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_label_repositories()
    |> Mrgr.Repo.one()
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, id) do
      from(q in query,
        where: q.installation_id == ^id
      )
    end

    # case sensitive
    def by_name(query, name) do
      from(q in query,
        where: q.name == ^name
      )
    end

    def for_repository(query, repo) do
      from(q in query,
        join: lr in assoc(q, :label_repositories),
        where: lr.repository_id == ^repo.id
      )
    end

    def with_repo_count(query) do
      from(q in query,
        join: lr in assoc(q, :label_repositories),
        select: %{q | repo_count: count(lr.id)},
        group_by: [q.id]
      )
    end

    def with_label_repositories(query) do
      from(q in query,
        join: lr in assoc(q, :label_repositories),
        join: r in assoc(lr, :repository),
        preload: [label_repositories: {lr, repository: r}]
      )
    end

    # look up the label_repo association directly
    def with_lr_assocs(query) do
      from(q in query,
        join: l in assoc(q, :label),
        join: r in assoc(q, :repository),
        preload: [label: l, repository: r]
      )
    end

    def select_repo_ids(query) do
      from(q in query,
        select: q.repository_id
      )
    end

    def tabs_for_user(query, user_id) do
      from(q in query,
        join: t in assoc(q, :pr_tab),
        where: t.user_id == ^user_id,
        preload: [pr_tab: t],
        order_by: [asc: t.inserted_at]
      )
    end
  end
end
