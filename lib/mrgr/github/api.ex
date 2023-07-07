defmodule Mrgr.Github.API do
  alias Mrgr.Github.API.Query

  @mod Application.compile_env!(:mrgr, :github)[:implementation]

  defdelegate create_comment(pull_request, message), to: @mod
  defdelegate fetch_filtered_pulls(installation, repo, opts), to: @mod
  defdelegate fetch_heavy_pulls(repo, params), to: @mod
  defdelegate fetch_repository_settings_graphql(repo), to: @mod
  defdelegate fetch_repository_data(repo), to: @mod
  defdelegate fetch_mergeable_statuses_on_open_pull_requests(repository), to: @mod
  defdelegate fetch_issue_comments(installation, repo, number), to: @mod
  defdelegate fetch_pr_review_comments(installation, repo, number), to: @mod
  defdelegate fetch_members(installation), to: @mod
  defdelegate fetch_teams(installation), to: @mod
  defdelegate fetch_repositories(installation), to: @mod
  defdelegate fetch_repository(installation, repository), to: @mod
  defdelegate fetch_all_repository_data(installation, opts \\ %{}), to: @mod
  defdelegate fetch_light_pr_data(pull_request), to: @mod
  defdelegate get_new_installation_token(installation), to: @mod
  defdelegate head_commit(pull_request, installation), to: @mod
  defdelegate check_suites_for_pr(pull_request), to: @mod
  defdelegate remove_review_request(pull_request, login), to: @mod
  defdelegate add_review_request(pull_request, login), to: @mod
  defdelegate update_repo_settings(repo, params), to: @mod

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
