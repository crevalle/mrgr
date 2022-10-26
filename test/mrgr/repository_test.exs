defmodule Mrgr.RepositoryTest do
  use Mrgr.DataCase

  describe "generate_default_file_change_alerts/1" do
    test "creates default file change alerts according to repo language" do
      %{id: id} = r = insert!(:repository, language: "Elixir")

      %{file_change_alerts: fcas} = Mrgr.Repository.generate_default_file_change_alerts(r)

      assert [
               %{
                 badge_text: "migration",
                 pattern: "priv/repo/migrations/*",
                 bg_color: "#dcfce7",
                 notify_user: true,
                 repository_id: ^id,
                 source: :system
               },
               %{
                 badge_text: "router",
                 pattern: "lib/**/router.ex",
                 bg_color: "#dbeafe",
                 notify_user: true,
                 repository_id: ^id,
                 source: :system
               },
               %{
                 badge_text: "dependencies",
                 pattern: "mix.lock",
                 bg_color: "#fef9c3",
                 notify_user: true,
                 repository_id: ^id,
                 source: :system
               }
             ] = fcas
    end

    test "creates nothing if repo language is unsupported" do
      r = insert!(:repository, language: "que")

      %{file_change_alerts: fcas} = Mrgr.Repository.generate_default_file_change_alerts(r)
      assert fcas == []
    end
  end

  describe "hydrate_branch_protection/1" do
    test "adds branch approval &c details to the repo" do
      r = insert!(:repository)

      updated = Mrgr.Repository.hydrate_branch_protection(r)

      assert updated.dismiss_stale_reviews
      refute updated.require_code_owner_reviews
      assert updated.required_approving_review_count == 2
    end

    test "gracefully handles unprotected branches" do
      r = insert!(:repository, name: "no-branch-protection")

      updated = Mrgr.Repository.hydrate_branch_protection(r)
      assert updated.required_approving_review_count == 0
    end
  end
end
