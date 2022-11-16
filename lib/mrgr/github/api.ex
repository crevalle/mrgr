defmodule Mrgr.Github.API do
  alias Mrgr.Github.API.Query

  @mod Application.compile_env!(:mrgr, :github)[:implementation]

  defdelegate commits(pull_request, installation), to: @mod
  defdelegate fetch_filtered_pulls(installation, repo, opts), to: @mod
  defdelegate fetch_pulls_graphql(installation, repo), to: @mod
  defdelegate fetch_repository_settings_graphql(repo), to: @mod
  defdelegate fetch_mergeable_statuses_on_open_pull_requests(repository), to: @mod
  defdelegate fetch_issue_comments(installation, repo, number), to: @mod
  defdelegate fetch_pr_review_comments(installation, repo, number), to: @mod
  defdelegate fetch_members(installation), to: @mod
  defdelegate fetch_repositories(installation), to: @mod
  defdelegate fetch_repository(installation, repository), to: @mod
  defdelegate fetch_repository_data(repository), to: @mod
  defdelegate fetch_most_pull_request_data(pull_request), to: @mod
  defdelegate get_new_installation_token(installation), to: @mod
  defdelegate head_commit(pull_request, installation), to: @mod
  defdelegate merge_pull_request(client, owner, repo, number, message), to: @mod
  defdelegate update_repo_settings(repo, params), to: @mod
  defdelegate update_branch_protection(repo, params), to: @mod

  def paged_requests(page \\ []) do
    Mrgr.Schema.GithubAPIRequest
    |> Query.all()
    |> Query.with_installation()
    |> Mrgr.Repo.paginate(page)
  end

  def preload_account(api_request) do
    Mrgr.Schema.GithubAPIRequest
    |> Query.by_id(api_request.id)
    |> Query.with_installation()
    |> Mrgr.Repo.one()
  end

  defmodule Query do
    use Mrgr.Query

    def all(query) do
      from(q in query,
        order_by: [desc: :inserted_at]
      )
    end

    def with_installation(query) do
      from(q in query,
        join: i in assoc(q, :installation),
        join: a in assoc(i, :account),
        preload: [installation: {i, account: a}]
      )
    end
  end
end
