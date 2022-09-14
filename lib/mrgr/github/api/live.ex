defmodule Mrgr.Github.API.Live do
  import Mrgr.Github.API.Utils

  def get_new_installation_token(client, id) do
    response = Tentacat.App.Installations.token(client, id)
    parse_into(response, Mrgr.Github.AccessToken)
  end

  def merge_pull_request(client, owner, repo, number, message) do
    response = Tentacat.Pulls.merge(client, owner, repo, number, message)
    handle_response(response)
  end

  def fetch_filtered_pulls(client, owner, repo, opts) do
    response = Tentacat.Pulls.filter(client, owner, repo, opts)
    result = parse(response)

    write_json(result, "test/response/repo/#{repo}-prs.json")

    result
  end

  def fetch_members(installation) do
    # expects installation to have account preloaded
    client = Mrgr.Github.Client.new(installation)

    response = Tentacat.Organizations.Members.list(client, installation.account.login)
    parse_into(response, Mrgr.Github.User)
  end

  def head_commit(merge, installation) do
    client = Mrgr.Github.Client.new(installation)

    {owner, name} = Mrgr.Schema.Repository.owner_name(merge.repository)
    sha = merge.head.sha

    response = Tentacat.Commits.find(client, sha, owner, name)

    parse(response)
  end

  def files_changed(merge, installation) do
    client = Mrgr.Github.Client.new(installation)

    {owner, name} = Mrgr.Schema.Repository.owner_name(merge.repository)
    number = merge.number

    response = Tentacat.Pulls.files(client, owner, name, number)

    parse(response)
  end

  def commits(merge, installation) do
    client = Mrgr.Github.Client.new(installation)

    {owner, name} = Mrgr.Schema.Repository.owner_name(merge.repository)
    number = merge.number

    response = Tentacat.Pulls.commits(client, owner, name, number)

    parse(response)
  end
end
