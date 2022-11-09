defmodule Mrgr.RepositorySettingsPolicyTest do
  use Mrgr.DataCase

  describe "create/1" do
    setup [:with_installation]

    test "creates a new profile", ctx do
      params = %{
        "installation_id" => ctx.installation.id,
        "title" => "hot pants",
        "apply_to_new_repos" => false,
        "settings" => %{
          "merge_commit_allowed" => true,
          "rebase_merge_allowed" => false,
          "squash_merge_allowed" => true,
          "required_approving_review_count" => 1
        }
      }

      {:ok, profile} = Mrgr.RepositorySettingsPolicy.create(params)

      assert profile.title == "hot pants"
      assert profile.installation_id == ctx.installation.id
      assert profile.settings.required_approving_review_count == 1
      assert profile.settings.merge_commit_allowed == true
    end

    test "associates the profile with one or more repos scoped to the installation", ctx do
      repo_1 = insert!(:repository, installation: ctx.installation)
      _repo_2 = insert!(:repository, installation: ctx.installation)
      repo_3 = insert!(:repository, installation: ctx.installation)
      repo_4 = insert!(:repository)

      params = %{
        "repository_ids" => [repo_1.id, repo_3.id, repo_4.id],
        "installation_id" => ctx.installation.id,
        "title" => "hot pants",
        "apply_to_new_repos" => false,
        "settings" => %{
          "merge_commit_allowed" => true,
          "rebase_merge_allowed" => false,
          "squash_merge_allowed" => true,
          "required_approving_review_count" => 1
        }
      }

      {:ok, profile} = Mrgr.RepositorySettingsPolicy.create(params)

      profile = Mrgr.Repo.preload(profile, :repositories, force: true)
      assert Enum.map(profile.repositories, & &1.id) == Enum.map([repo_1, repo_3], & &1.id)
    end
  end

  import Ecto.Query

  describe "update/2" do
    test "updates attrs and repos" do
      profile = insert!(:repository_settings_policy)

      from(r in Mrgr.Schema.Repository,
        where: r.repository_settings_policy_id == ^profile.id
      )
      |> Mrgr.Repo.all()

      profile
      |> Mrgr.Repo.preload(:repositories, force: true)
      |> Map.get(:repositories)

      repo_1 =
        insert!(:repository,
          repository_settings_policy_id: profile.id,
          installation: profile.installation
        )

      repo_2 = insert!(:repository, installation: profile.installation)
      repo_3 = insert!(:repository)

      {:ok, updated} =
        Mrgr.RepositorySettingsPolicy.update(profile, %{
          "title" => "yo momma",
          "repository_ids" => [repo_2.id, repo_3.id]
        })

      updated = Mrgr.Repo.preload(updated, :repositories, force: true)

      old_repo = Mrgr.Repo.get(Mrgr.Schema.Repository, repo_1.id)
      assert is_nil(old_repo.repository_settings_policy_id)

      assert updated.title == "yo momma"

      assert Enum.map(updated.repositories, & &1.id) == Enum.map([repo_2], & &1.id)
    end
  end

  def with_installation(_ctx) do
    %{installation: insert!(:installation)}
  end
end
