defmodule Mrgr.Label do
  use Mrgr.PubSub.Event

  alias __MODULE__.Query
  alias Mrgr.Schema.Label, as: Schema

  def for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.with_repositories()
    |> Query.order_by_insensitive(asc: :name)
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

  @spec create_from_form(map) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_from_form(params) do
    %Schema{}
    |> Schema.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, label} ->
        Mrgr.PubSub.broadcast_to_installation(label, @label_created)
        push_to_all_repos_async(label)
        {:ok, label}

      error ->
        error
    end
  end

  @spec update_from_form(Schema.t(), map) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def update_from_form(schema, params) do
    schema
    |> Schema.changeset(params)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, label} ->
        Mrgr.PubSub.broadcast_to_installation(label, @label_updated)
        label = update_repo_associations(label, params["label_repositories"])
        push_to_all_repos_async(label)
        {:ok, label}

      error ->
        error
    end
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

    delete_repo_association(lr)

    create_for_repo(params, repo)
  end

  @spec update_repo_associations(Schema.t(), list() | nil) :: Schema.t()
  def update_repo_associations(label, repository_ids) when is_list(repository_ids) do
    new_ids = Enum.map(repository_ids, fn id -> id["repository_id"] end) |> MapSet.new()

    # here we go
    # iterate through current association.  if its repo is present in the new id list, stash that id
    # if it is absent from the new list, it is to be deleted
    #
    # take the difference of our new id list with our stashed ids.  the remainder is the new associations
    # that need creating
    retained_associations =
      label.label_repositories
      |> Enum.reduce([], fn lr, acc ->
        case MapSet.member?(new_ids, lr.repository_id) do
          true ->
            [lr | acc]

          false ->
            delete_repo_association_async(lr)
            acc
        end
      end)

    retained_repository_ids = MapSet.new(Enum.map(retained_associations, & &1.repository_id))

    ids_to_add = MapSet.difference(new_ids, retained_repository_ids)

    new_associations =
      Enum.map(ids_to_add, fn repository_id ->
        lr = associate_with_repo(label.id, repository_id)

        %{label_repository_id: lr.id}
        |> Mrgr.Worker.PushLabel.new()
        |> Oban.insert()

        lr
      end)

    %{label | label_repositories: retained_associations ++ new_associations}
  end

  def update_repo_associations(label, _ids), do: label

  def delete_repo_association_async(lr) do
    %{label_repository_id: lr.id}
    |> Mrgr.Worker.DeleteLabel.new()
    |> Oban.insert()
  end

  def delete_repo_association(%{node_id: nil} = lr) do
    Mrgr.Repo.delete(lr)
  end

  def delete_repo_association(lr) do
    Mrgr.Github.API.delete_label_from_repo(lr.node_id, lr.repository)
    Mrgr.Repo.delete(lr)
  end

  def delete_async(label) do
    %{id: label.id}
    |> Mrgr.Worker.DeleteLabel.new()
    |> Oban.insert()
  end

  def delete(label) do
    Enum.map(label.label_repositories, &delete_repo_association/1)

    Mrgr.Repo.delete(label)

    Mrgr.PubSub.broadcast_to_installation(label, @label_deleted)
  end

  def delete_from_webhook(%{label: label} = lr) do
    case has_several_repos?(label) do
      true ->
        Mrgr.Label.delete_repo_association(lr)

      false ->
        # delete takes care of the associations
        label = %{label | label_repositories: [lr]}
        delete(label)
    end
  end

  def push_to_all_repos_async(label) do
    %{id: label.id}
    |> Mrgr.Worker.PushLabel.new()
    |> Oban.insert()
  end

  def push_to_all_repos(label) do
    lrs =
      Enum.map(label.label_repositories, fn lr ->
        push_label_to_repo(label, lr)
      end)

    %{label | label_repositories: lrs}
  end

  def push_label_to_repo(label, %{node_id: nil} = lr) do
    response = Mrgr.Github.API.create_label(label, lr.repository)

    store_node_id(lr, response)
  end

  def push_label_to_repo(label, lr) do
    Mrgr.Github.API.update_label(label, lr.repository, lr.node_id)
    lr
  end

  defp store_node_id(label_repository, %{"createLabel" => %{"label" => %{"id" => node_id}}}) do
    label_repository
    |> Ecto.Changeset.change(%{node_id: node_id})
    |> Mrgr.Repo.update!()
  end

  defp store_node_id(label_repository, _bum_response), do: label_repository

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

    ### preloads both associations off the label, so
    # you *can't* do label_repository.repository
    def with_repositories(query) do
      from(q in query,
        join: lr in assoc(q, :label_repositories),
        join: r in assoc(q, :repositories),
        preload: [label_repositories: lr, repositories: r]
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
  end
end
