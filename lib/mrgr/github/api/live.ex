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

  def fetch_repositories(installation) do
    request!(
      &Tentacat.Repositories.list_orgs/2,
      installation,
      [installation.account.login]
    )
  end

  def head_commit(merge, installation) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(merge.repository)
    sha = merge.head.sha

    request!(&Tentacat.Commits.find/4, installation, [sha, owner, name])
  end

  def files_changed(merge, installation) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(merge.repository)
    number = merge.number

    request!(&Tentacat.Pulls.files/4, installation, [owner, name, number])
  end

  def commits(merge, installation) do
    {owner, name} = Mrgr.Schema.Repository.owner_name(merge.repository)
    number = merge.number

    request!(&Tentacat.Pulls.commits/4, installation, [owner, name, number])
  end

  def request!(f, installation, args) do
    client = generate_client!(installation)
    request!(f, installation, client, args)
  end

  def request!(f, installation, client, args) do
    api_request = create_api_request(installation, f)

    result = do_request!(f, [client] ++ args)

    complete_api_request(api_request, result)

    result.data
  end

  defp do_request!(f, args) do
    start_time = DateTime.utc_now()

    {code, data, response} = apply(f, args)

    elapsed_time = DateTime.diff(DateTime.utc_now(), start_time, :millisecond)

    %{response_code: code, data: data, response: response, elapsed_time: elapsed_time}
  end

  defp generate_client!(installation) do
    # may call out to GH to refresh client token
    Mrgr.Github.Client.new(installation)
  end

  defp create_api_request(installation, api_call) do
    params = %{
      installation_id: installation.id,
      api_call: inspect(api_call)
    }

    params
    |> Mrgr.Schema.GithubAPIRequest.create_changeset()
    |> Mrgr.Repo.insert!()
  end

  defp complete_api_request(schema, params) do
    response_headers = Map.new(params.response.headers)

    attrs =
      params
      |> Map.put(:response_headers, response_headers)

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
