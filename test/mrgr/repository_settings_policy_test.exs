defmodule Mrgr.RepositorySettingsPolicyTest do
  use Mrgr.DataCase

  describe "create/1" do
    setup [:with_installation]

    test "creates a new policy", ctx do
      params = %{
        "installation_id" => ctx.installation.id,
        "name" => "hot pants",
        "apply_to_new_repos" => false,
        "settings" => %{
          "merge_commit_allowed" => true,
          "rebase_merge_allowed" => false,
          "squash_merge_allowed" => true,
          "required_approving_review_count" => 1
        }
      }

      {:ok, policy} = Mrgr.RepositorySettingsPolicy.create(params)

      assert policy.name == "hot pants"
      assert policy.installation_id == ctx.installation.id
      assert policy.settings.required_approving_review_count == 1
      assert policy.settings.merge_commit_allowed == true
    end

    test "associates the policy with one or more repos scoped to the installation", ctx do
      repo_1 = insert!(:repository, installation: ctx.installation)
      _repo_2 = insert!(:repository, installation: ctx.installation)
      repo_3 = insert!(:repository, installation: ctx.installation)
      repo_4 = insert!(:repository)

      params = %{
        "repository_ids" => [repo_1.id, repo_3.id, repo_4.id],
        "installation_id" => ctx.installation.id,
        "name" => "hot pants",
        "apply_to_new_repos" => false,
        "settings" => %{
          "merge_commit_allowed" => true,
          "rebase_merge_allowed" => false,
          "squash_merge_allowed" => true,
          "required_approving_review_count" => 1
        }
      }

      {:ok, policy} = Mrgr.RepositorySettingsPolicy.create(params)

      policy = Mrgr.Repo.preload(policy, :repositories, force: true)
      assert Enum.map(policy.repositories, & &1.id) == Enum.map([repo_1, repo_3], & &1.id)
    end
  end

  import Ecto.Query

  describe "update/2" do
    test "updates attrs and repos" do
      policy = insert!(:repository_settings_policy)

      from(r in Mrgr.Schema.Repository,
        where: r.repository_settings_policy_id == ^policy.id
      )
      |> Mrgr.Repo.all()

      policy
      |> Mrgr.Repo.preload(:repositories, force: true)
      |> Map.get(:repositories)

      repo_1 =
        insert!(:repository,
          repository_settings_policy_id: policy.id,
          installation: policy.installation
        )

      repo_2 = insert!(:repository, installation: policy.installation)
      repo_3 = insert!(:repository)

      {:ok, updated} =
        Mrgr.RepositorySettingsPolicy.update(policy, %{
          "name" => "yo momma",
          "repository_ids" => [repo_2.id, repo_3.id]
        })

      updated = Mrgr.Repo.preload(updated, :repositories, force: true)

      old_repo = Mrgr.Repo.get(Mrgr.Schema.Repository, repo_1.id)
      assert is_nil(old_repo.repository_settings_policy_id)

      assert updated.name == "yo momma"

      assert Enum.map(updated.repositories, & &1.id) == Enum.map([repo_2], & &1.id)
    end
  end

  def with_installation(_ctx) do
    %{installation: insert!(:installation)}
  end
end
