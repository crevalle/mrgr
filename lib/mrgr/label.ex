defmodule Mrgr.Label do
  use Mrgr.PubSub.Event

  alias __MODULE__.Query
  alias Mrgr.Schema.Label, as: Schema

  ### RELEASE TASK

  def migrate_color_tags do
    labels = Mrgr.Repo.all(Schema)

    Enum.each(labels, fn label ->
      label
      |> Ecto.Changeset.change(%{color: String.replace(label.color, "#", "")})
      |> Mrgr.Repo.update()
    end)

    alerts = Mrgr.Repo.all(Mrgr.Schema.FileChangeAlert)

    Enum.each(alerts, fn alert ->
      alert
      |> Ecto.Changeset.change(%{color: String.replace(alert.color, "#", "")})
      |> Mrgr.Repo.update()
    end)
  end

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

  def find_or_create_for_repo(params, repo) do
    case find_by_name_for_repo(params["name"], repo) do
      %Schema{} = label ->
        label

      nil ->
        case find_by_name_for_installation(params["name"], repo.installation_id) do
          nil -> create_for_repo(params, repo)
          label -> associate_with_repo(label, repo)
        end
    end

    # "color" => "0075ca",
    # "description" => "Improvements or additions to documentation",
    # "name" => "documentation"
    # },
  end

  def create_for_repo(params, repo) do
    params = Map.put(params, "installation_id", repo.installation_id)

    with cs <- Schema.simple_changeset(%Schema{}, params),
         {:ok, label} <- Mrgr.Repo.insert(cs),
         {:ok, _label_repository} <- associate_with_repo(label, repo) do
      {:ok, label}
    end
  end

  def associate_with_repo(label, repo) do
    %Mrgr.Schema.LabelRepository{}
    |> Mrgr.Schema.LabelRepository.changeset(%{label_id: label.id, repository_id: repo.id})
    |> Mrgr.Repo.insert()
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
    def preload_repositories(query) do
      from(q in query,
        join: lr in assoc(q, :label_repositories),
        join: r in assoc(q, :repositories),
        preload: [label_repositories: lr, repositories: r]
      )
    end
  end
end
