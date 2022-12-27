defmodule Mrgr.Github.API.Live do
  use Mrgr.PubSub.Event

  import Mrgr.Github.API.Utils

  def get_new_installation_token(installation) do
    client = Tentacat.Client.new(%{jwt: Mrgr.Github.JwtToken.signed_jwt()})

    result =
      request!(
        &Tentacat.App.Installations.token/2,
        installation,
        client,
        [installation.external_id]
      )

    parse_into(result, Mrgr.Github.AccessToken)
  end

  def merge_pull_request(client, owner, repo, number, message) do
    response = Tentacat.Pulls.merge(client, owner, repo, number, message)
    handle_response(response)
  end

  def fetch_most_pull_request_data(pull_request) do
    # don't feel like paginating today.  if >99 files have changed,
    # you've got other problems.
    github_limit = 100

    query = """
      query {
        node(id:"#{pull_request.node_id}") {
          ... on PullRequest {
            id
            number
            mergeStateStatus
            mergeable
            title
            files(first: #{github_limit}) {
              nodes #{Mrgr.Github.PullRequest.GraphQL.files()}
            }
            labels(first: #{github_limit}, orderBy: {direction: ASC, field: NAME}) {
              nodes {
                #{Mrgr.Github.Label.GraphQL.basic()}
              }
            }
          }
        }
      }
    """

    neuron_request!(pull_request.repository.installation_id, query)
  end

  def fetch_mergeable_statuses_on_open_pull_requests(repository) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(repository)

    query = """
      query {
        repository(owner:"#{owner}", name:"#{name}") {
          pullRequests(last: 50, states: [OPEN]) {
            edges {
              node {
                id
                number
                mergeStateStatus
                mergeable
              }
            }
          }
        }
      }
    """

    neuron_request!(repository.installation_id, query)
  end

  def fetch_all_repository_data(installation, opts \\ %{}) do
    # this pagination is garbage
    per_page = Map.get(opts, :per_page, 50)
    start_at = Map.get(opts, :after)

    next_cursor = if start_at, do: "after: \"#{start_at}\"", else: nil

    opts =
      [
        "first: #{per_page}",
        next_cursor
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(", ")

    query = """
    {
      viewer {
        repositories(#{opts}) {
          pageInfo {
            startCursor
            hasNextPage
            endCursor
          }
          nodes {
            #{Mrgr.Github.Repository.GraphQL.basic()}
            #{Mrgr.Github.Repository.GraphQL.settings()}
            #{Mrgr.Github.Repository.GraphQL.primary_language()}
          }
        }
      }
    }
    """

    neuron_request!(installation.id, query)
  end

  def fetch_repository_data(repository) do
    query = """
      query {
        node(id:"#{repository.node_id}") {
          ... on Repository {
            #{Mrgr.Github.Repository.GraphQL.basic()}
            #{Mrgr.Github.Repository.GraphQL.settings()}
            #{Mrgr.Github.Repository.GraphQL.primary_language()}
          }
        }
      }
    """

    neuron_request!(repository.installation_id, query)
  end

  def fetch_repository_settings_graphql(repository) do
    query = """
      query {
        node(id:"#{repository.node_id}") {
          ... on Repository {
            #{Mrgr.Github.Repository.GraphQL.settings()}
          }
        }
      }
    """

    neuron_request!(repository.installation_id, query)
  end

  def fetch_pulls_graphql(installation, repo, params) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(repo)

    query = """
      query {
        repository(owner:"#{owner}", name:"#{name}") {
          pullRequests(#{params}) {
            edges {
              node {
                assignees(first: 20) {
                  nodes {
                    #{Mrgr.Github.User.GraphQL.user()}
                  }
                }
                author {
                  ... on User {
                    #{Mrgr.Github.User.GraphQL.actor()}
                  }
                }
                createdAt
                databaseId
                mergeStateStatus
                mergeable
                mergedAt
                id
                number
                permalink
                state
                title
                headRef #{Mrgr.Github.PullRequest.GraphQL.head_ref()}
                reviewRequests(first: 20) {
                  nodes {
                    databaseId
                    requestedReviewer {
                      ... on User {
                        #{Mrgr.Github.User.GraphQL.user()}
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    """

    neuron_request!(installation, query)
  end

  def update_repo_settings(repo, params) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(repo)

    request!(&Tentacat.Repositories.update/4, repo.installation_id, [owner, name, params])
  end

  def update_branch_protection(repo, params) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(repo)
    branch_name = repo.settings.default_branch_name

    request!(&Tentacat.Repositories.Branches.update_protection/5, repo.installation_id, [
      owner,
      name,
      branch_name,
      params
    ])
  end

  def fetch_filtered_pulls(installation, repo, opts) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(repo)

    request!(&Tentacat.Pulls.filter/4, installation, [owner, name, opts])
  end

  def fetch_issue_comments(installation, repo, number) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(repo)

    request!(&Tentacat.Issues.Comments.list/4, installation, [owner, name, number])
  end

  def fetch_pr_review_comments(installation, repo, number) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(repo)

    request!(&Tentacat.Pulls.Comments.list/4, installation, [owner, name, number])
  end

  def fetch_members(installation) do
    result =
      request!(
        &Tentacat.Organizations.Members.list/2,
        installation,
        [installation.account.login]
      )

    parse_into(result, Mrgr.Github.User)
  end

  def fetch_teams(installation) do
    result =
      request!(
        &Tentacat.Organizations.Teams.list/2,
        installation,
        [installation.account.login]
      )

    parse_into(result, Mrgr.Github.Team)
  end

  def fetch_repositories(installation) do
    request!(
      &Tentacat.Repositories.list_orgs/2,
      installation,
      [installation.account.login]
    )
  end

  def fetch_repository(installation, repository) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(repository)

    request!(
      &Tentacat.Repositories.repo_get/3,
      installation,
      [owner, name]
    )
  end

  def head_commit(pull_request, installation) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(pull_request.repository)
    sha = Mrgr.Schema.PullRequest.head(pull_request).sha

    request!(&Tentacat.Commits.find/4, installation, [sha, owner, name])
  end

  def commits(pull_request) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(pull_request.repository)
    number = pull_request.number

    request!(&Tentacat.Pulls.commits/4, pull_request.repository, [owner, name, number])
  end

  # doesn't get them all, just gets ones for HEAD
  def check_suites_for_pr(pull_request) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(pull_request.repository)

    ref =
      pull_request
      |> Mrgr.Schema.PullRequest.head()
      |> Map.get(:sha)

    request!(&Tentacat.CheckSuites.list_for_ref/4, pull_request.repository, [owner, name, ref])
  end

  def create_label(label, repository) do
    mutation = """
    mutation ($var: CreateLabelInput!) {
      createLabel(input:$var) {
        label {
          color
          id
          name
        }
      }
    }
    """

    params = %{
      var: %{
        color: label.color,
        description: label.description,
        name: label.name,
        repositoryId: repository.node_id
      }
    }

    neuron_request!(repository, mutation, params)
  end

  def update_label(label, repository, node_id) do
    mutation = """
    mutation ($var: UpdateLabelInput!) {
      updateLabel(input:$var) {
        label {
          color
          id
          name
        }
      }
    }
    """

    params = %{
      var: %{
        color: label.color,
        description: label.description,
        name: label.name,
        id: node_id
      }
    }

    neuron_request!(repository, mutation, params)
  end

  def delete_label_from_repo(node_id, repository) do
    # we don't send in a clientMutationId but I need to ask the server
    # for some kind of response or it'll 💣

    mutation = """
    mutation ($var: DeleteLabelInput!) {
      deleteLabel(input:$var) {
        clientMutationId
      }
    }
    """

    params = %{
      var: %{
        id: node_id
      }
    }

    neuron_request!(repository, mutation, params)
  end

  # will accept not just an installation, but anything with an `installation_id`
  def neuron_request!(installation, query, params \\ %{}) do
    token = Mrgr.Github.Client.graphql(installation)

    opts = [
      url: "https://api.github.com/graphql",
      connection_opts: [recv_timeout: 15_000],
      headers: [
        Authorization: "bearer #{token}",
        Accept: "application/vnd.github.merge-info-preview+json",
        Accept: "application/vnd.github.bane-preview+json"
      ]
    ]

    neuron_request!(installation, query, params, opts)
  end

  def neuron_request!(installation, query, params, opts) do
    # logs the query string
    record = create_api_request(installation, query)

    result = do_neuron_request!(query, params, opts)

    complete_api_request(record, result)

    result.data
  end

  defp do_neuron_request!(query, params, opts) do
    start_time = DateTime.utc_now()

    {status, response} = Neuron.query(query, params, opts)

    elapsed_time = DateTime.diff(DateTime.utc_now(), start_time, :millisecond)

    data =
      case status do
        :ok ->
          response.body["data"]

        :error ->
          # message and documentation_url
          response.body
      end

    %{
      response_code: response.status_code,
      data: data,
      response: response,
      elapsed_time: elapsed_time,
      response_headers: Map.new(response.headers)
    }
  end

  def request!(f, client_source, args) do
    client = generate_client!(client_source)
    request!(f, client_source, client, args)
  end

  def request!(f, client_source, client, args) do
    api_request = create_api_request(client_source, f)

    result = do_request!(f, [client] ++ args)

    complete_api_request(api_request, result)

    result.data
  end

  defp do_request!(f, args) do
    start_time = DateTime.utc_now()

    {code, data, response} = apply(f, args)

    elapsed_time = DateTime.diff(DateTime.utc_now(), start_time, :millisecond)

    %{
      response_code: code,
      data: data,
      response: response,
      elapsed_time: elapsed_time,
      response_headers: Map.new(response.headers)
    }
  end

  defp generate_client!(client_source) do
    # can create with an installation or anything with an installation_id
    # may call out to GH to refresh client token
    Mrgr.Github.Client.new(client_source)
  end

  defp create_api_request(%{installation_id: id}, api_call), do: create_api_request(id, api_call)
  defp create_api_request(%{id: id}, api_call), do: create_api_request(id, api_call)

  defp create_api_request(installation_id, api_call) do
    params = %{
      installation_id: installation_id,
      api_call: inspect(api_call)
    }

    params
    |> Mrgr.Schema.GithubAPIRequest.create_changeset()
    |> Mrgr.Repo.insert!()
  end

  defp complete_api_request(schema, attrs) do
    schema
    |> Mrgr.Schema.GithubAPIRequest.complete_changeset(attrs)
    |> Mrgr.Repo.update!()
    |> Mrgr.Github.API.preload_account()
    |> publish_request_completed()
  end

  defp publish_request_completed(api_request) do
    topic = Mrgr.PubSub.Topic.admin()
    Mrgr.PubSub.broadcast(api_request, topic, @api_request_completed)

    api_request
  end
end
