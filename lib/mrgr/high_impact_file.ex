defmodule Mrgr.HighImpactFile do
  alias Mrgr.Schema.HighImpactFile, as: Schema
  alias Mrgr.HighImpactFile.Query

  use Mrgr.PubSub.Event

  def for_repository(%{id: repo_id}) do
    Schema
    |> Query.for_repository(repo_id)
    |> Query.order_by_pattern()
    |> Mrgr.Repo.all()
  end

  def for_pull_request(
        %{repository: %{high_impact_files: %Ecto.Association.NotLoaded{}}} = pull_request
      ) do
    repo = Mrgr.Repo.preload(pull_request.repository, :high_impact_files)
    pull_request = %{pull_request | repository: repo}

    for_pull_request(pull_request)
  end

  def for_pull_request(%{repository: %{high_impact_files: hifs}} = pull_request) do
    hifs
    |> Enum.filter(&applies_to_pull_request?(&1, pull_request))
    |> Enum.uniq_by(& &1.id)
  end

  def clear_from_pr(pull_request) do
    pull_request = Mrgr.Repo.preload(pull_request, :high_impact_file_pull_requests)

    pull_request.high_impact_file_pull_requests
    |> Enum.map(&Mrgr.Repo.delete/1)

    %{pull_request | high_impact_file_pull_requests: [], high_impact_files: []}
  end

  def create_for_pull_request(pull_request, hifs) do
    assocs =
      Enum.map(hifs, fn hif ->
        params = %{
          pull_request_id: pull_request.id,
          high_impact_file_id: hif.id
        }

        %Mrgr.Schema.HighImpactFilePullRequest{}
        |> Mrgr.Schema.HighImpactFilePullRequest.changeset(params)
        |> Mrgr.Repo.insert!()
      end)

    %{pull_request | high_impact_files: hifs, high_impact_file_pull_requests: assocs}
  end

  def applies_to_pull_request?(hif, pull_request) do
    hif
    |> matching_filenames(pull_request)
    |> Enum.any?()
  end

  def matching_filenames(hif, pull_request) do
    filenames = pull_request.files_changed

    Enum.filter(filenames, &pattern_matches_filename?(&1, hif))
  end

  def pattern_matches_filename?(filename, %Schema{pattern: pattern}) do
    pattern_matches_filename?(filename, pattern)
  end

  def pattern_matches_filename?(filename, pattern) when is_bitstring(pattern) do
    PathGlob.match?(filename, pattern)
  end

  def delete(hif) do
    hif
    |> Mrgr.Repo.delete()
    |> case do
      {:ok, deleted} = res ->
        broadcast(deleted, @high_impact_file_deleted)
        res

      {:error, _cs} = error ->
        error
    end
  end

  def create(params) do
    %Schema{}
    |> Schema.changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, created} = res ->
        broadcast(created, @high_impact_file_created)
        res

      {:error, _cs} = error ->
        error
    end
  end

  def defaults_for_repo(%{language: "Elixir"} = repository) do
    [
      %{
        name: "migration",
        pattern: "priv/repo/migrations/*",
        color: "#dcfce7",
        notify_user: true,
        repository_id: repository.id,
        source: :system
      },
      %{
        name: "router",
        pattern: "lib/**/router.ex",
        color: "#dbeafe",
        notify_user: true,
        repository_id: repository.id,
        source: :system
      },
      %{
        name: "dependencies",
        pattern: "mix.lock",
        color: "#fef9c3",
        notify_user: true,
        repository_id: repository.id,
        source: :system
      }
    ]
  end

  def defaults_for_repo(_unsupported), do: []

  def update(hif, params) do
    hif
    |> Schema.update_changeset(params)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, updated} = res ->
        broadcast(updated, @high_impact_file_updated)
        res

      {:error, _cs} = error ->
        error
    end
  end

  defp broadcast(hif, event) do
    hif = Mrgr.Repo.preload(hif, :repository)

    installation_id = hif.repository.installation_id
    topic = Mrgr.PubSub.Topic.installation(installation_id)

    Mrgr.PubSub.broadcast(hif, topic, event)
  end

  defmodule Query do
    use Mrgr.Query

    def for_repository(query, repo_id) do
      from(q in query,
        where: q.repository_id == ^repo_id
      )
    end

    def order_by_pattern(query) do
      from(q in query,
        order_by: [desc: q.pattern]
      )
    end
  end
end
