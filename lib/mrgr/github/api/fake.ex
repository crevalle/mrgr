defmodule Mrgr.Github.API.Fake do
  def get_new_installation_token(_client, _id) do
    []
  end

  def merge_pull_request(_client, _owner, _repo, _number, _message) do
    {:ok, %{"sha" => "0xdeadbeef"}}
  end

  def fetch_filtered_pulls(_client, _owner, _repo, _opts) do
    %{}
  end

  def fetch_members(_client, _login) do
    []
  end

  def head_commit(_merge, _installation) do
    %{}
  end

  def files_changed(_merge, _installation) do
    %{}
  end

  def commits(_merge, _installation) do
    %{}
  end
end
