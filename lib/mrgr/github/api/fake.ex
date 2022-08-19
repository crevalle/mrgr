defmodule Mrgr.Github.API.Fake do
  def get_new_installation_token(client, id) do
    []
  end

  def merge_pull_request(client, owner, repo, number, message) do
    {:ok, "socks"}
  end

  def fetch_filtered_pulls(client, owner, repo, opts) do
    %{}
  end

  def fetch_members(client, login) do
    []
  end

  def head_commit(merge, installation) do
    %{}
  end

  def files_changed(merge, installation) do
    %{}
  end

  def commits(merge, installation) do
    %{}
  end
end
