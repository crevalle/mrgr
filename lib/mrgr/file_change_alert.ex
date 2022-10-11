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

  def for_merge(%{repository: %{file_change_alerts: alerts}} = merge) do
    Enum.filter(alerts, &applies_to_merge?(&1, merge))
  end

  def applies_to_merge?(alert, merge) do
    alert
    |> matching_filenames(merge)
    |> Enum.any?()
  end

  def matching_filenames(alert, merge) do
    filenames = merge.files_changed
    pattern = alert.pattern

    Enum.filter(filenames, &pattern_matches_filename?(&1, pattern))
  end

  def pattern_matches_filename?(filename, pattern) do
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
