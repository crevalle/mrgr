defmodule Mrgr.ChecklistTemplate do
  alias Mrgr.Schema.ChecklistTemplate, as: Schema
  alias Mrgr.ChecklistTemplate.Query

  def for_installation(installation) do
    Schema
    |> Query.for_installation(installation.id)
    |> Query.with_creator()
    |> Query.with_repositories()
    |> Query.cron()
    |> Mrgr.Repo.all()
  end

  def for_repository(repository) do
    Schema
    |> Query.for_repository(repository.id)
    |> Query.with_creator()
    |> Query.with_repositories()
    |> Query.cron()
    |> Mrgr.Repo.all()
  end

  def create(params) do
    %Schema{}
    |> Schema.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, template} ->
        # ensure user owns the repos
        repos = Mrgr.Repository.find_for_user(params["creator"], params["repository_ids"])

        Enum.map(repos, fn repo ->
          %Mrgr.Schema.ChecklistTemplateRepository{
            repository_id: repo.id,
            checklist_template_id: template.id
          }
          |> Mrgr.Repo.insert!()
        end)

        {:ok, Mrgr.Repo.preload(template, :repositories)}

      {:error, _changeset} = error ->
        error
    end
  end

  def create_checklist(template, merge) do
    check_attrs = extract_check_text(template.check_templates)

    attrs = %{
      title: template.title,
      checklist_template: template,
      merge: merge,
      checks: check_attrs
    }

    Mrgr.Checklist.create!(attrs)
  end

  defp extract_check_text(check_templates) do
    # ignore the other attributes
    Enum.map(check_templates, fn ct -> %{text: ct.text} end)
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, installation_id) do
      from(q in query,
        join: i in assoc(q, :installation),
        where: q.installation_id == ^installation_id,
        preload: [installation: i]
      )
    end

    def with_creator(query) do
      from(q in query,
        join: c in assoc(q, :creator),
        preload: [creator: c]
      )
    end

    def with_repositories(query) do
      case has_named_binding?(query, :repositories) do
        true ->
          query

        false ->
          from(q in query,
            left_join: r in assoc(q, :repositories),
            as: :repositories,
            preload: [repositories: r]
          )
      end
    end

    def for_repository(query, repository_id) do
      from([q, repositories: r] in with_repositories(query),
        where: r.id == ^repository_id
      )
    end
  end
end
