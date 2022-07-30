defmodule Mrgr.FileChangeAlert do
  alias Mrgr.Schema.FileChangeAlert, as: Schema
  alias Mrgr.FileChangeAlert.Query

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
    pattern_matches_filenames?(alert.pattern, merge.files_changed)
  end

  def pattern_matches_filenames?(pattern, filenames) do
    Enum.any?(filenames, fn name -> PathGlob.match?(name, pattern) end)
  end

  def delete(alert) do
    Mrgr.Repo.delete(alert)
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
