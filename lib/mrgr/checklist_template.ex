defmodule Mrgr.ChecklistTemplate do
  alias Mrgr.ChecklistTemplate.Query

  def for_installation(installation) do
    Mrgr.Schema.ChecklistTemplate
    |> Query.for_installation(installation.id)
    |> Query.with_creator()
    |> Query.cron()
    |> Mrgr.Repo.all()
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
  end
end
