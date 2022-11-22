defmodule Mrgr.FileChangeAlert do
  alias Mrgr.Schema.FileChangeAlert, as: Schema
  alias Mrgr.FileChangeAlert.Query

  use Mrgr.PubSub.Event

  def for_repository(%{id: repo_id}) do
    Schema
    |> Query.for_repository(repo_id)
    |> Query.order_by_pattern()
    |> Mrgr.Repo.all()
  end

  def for_pull_request(%{repository: %{file_change_alerts: alerts}} = pull_request) do
    Enum.filter(alerts, &applies_to_pull_request?(&1, pull_request))
  end

  def applies_to_pull_request?(alert, pull_request) do
    alert
    |> matching_filenames(pull_request)
    |> Enum.any?()
  end

  def matching_filenames(alert, pull_request) do
    filenames = pull_request.files_changed

    Enum.filter(filenames, &pattern_matches_filename?(&1, alert))
  end

  def pattern_matches_filename?(filename, %Schema{pattern: pattern}) do
    pattern_matches_filename?(filename, pattern)
  end

  def pattern_matches_filename?(filename, pattern) when is_bitstring(pattern) do
    PathGlob.match?(filename, pattern)
  end

  def delete(alert) do
    alert
    |> Mrgr.Repo.delete()
    |> case do
      {:ok, deleted} = res ->
        broadcast(deleted, @file_change_alert_deleted)
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
        broadcast(created, @file_change_alert_created)
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
        bg_color: "#dcfce7",
        notify_user: true,
        repository_id: repository.id,
        source: :system
      },
      %{
        name: "router",
        pattern: "lib/**/router.ex",
        bg_color: "#dbeafe",
        notify_user: true,
        repository_id: repository.id,
        source: :system
      },
      %{
        name: "dependencies",
        pattern: "mix.lock",
        bg_color: "#fef9c3",
        notify_user: true,
        repository_id: repository.id,
        source: :system
      }
    ]
  end

  def defaults_for_repo(_unsupported), do: []

  def update(alert, params) do
    alert
    |> Schema.update_changeset(params)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, updated} = res ->
        broadcast(updated, @file_change_alert_updated)
        res

      {:error, _cs} = error ->
        error
    end
  end

  defp broadcast(alert, event) do
    alert = Mrgr.Repo.preload(alert, :repository)

    installation_id = alert.repository.installation_id
    topic = Mrgr.PubSub.Topic.installation(installation_id)

    Mrgr.PubSub.broadcast(alert, topic, event)
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
