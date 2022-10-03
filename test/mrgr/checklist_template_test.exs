defmodule Mrgr.ChecklistTemplateTest do
  use Mrgr.DataCase

  describe "create/1" do
    test "creates a new template with correct associations" do
      membership = insert!(:membership)
      installation = membership.installation
      creator = membership.member.user
      repository = insert!(:repository, installation: installation)

      params = %{
        "title" => "a new checklist",
        "installation" => installation,
        "creator" => creator,
        "repository_ids" => [repository.id],
        "check_templates" => %{"0" => %{"temp_id" => "", "text" => "a check"}}
      }

      {:ok, template} = Mrgr.ChecklistTemplate.create(params)

      assert template.title == "a new checklist"
      assert template.creator.id == creator.id

      assert Enum.count(template.repositories) == 1

      ck_template = hd(template.check_templates)
      assert ck_template.text == "a check"
    end
  end

  describe "for_repository/1" do
    test "finds templates that apply to that repository" do
      repository = insert!(:repository)
      template = insert!(:checklist_template, installation: repository.installation)

      insert!(:checklist_template_repository,
        checklist_template: template,
        repository: repository
      )

      res = Mrgr.ChecklistTemplate.for_repository(repository)
      assert Enum.count(res) == 1
      t = hd(res)
      assert t.id == template.id

      assert Enum.count(t.repositories) == 1
      r = hd(t.repositories)
      assert r.id == repository.id
    end
  end
end
