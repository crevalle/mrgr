defmodule Mrgr.Github.API.Fake do
  def get_new_installation_token(_installation) do
    []
  end

  def merge_pull_request(_client, _owner, _repo, _number, _message) do
    {:ok, %{"sha" => "0xdeadbeef"}}
  end

  def fetch_filtered_pulls(_installation, _repo, _opts) do
    %{}
  end

  def fetch_issue_comments(_installation, _repo, _number) do
    []
  end

  def fetch_pr_review_comments(_installation, _repo, _number) do
    []
  end

  def fetch_members(_installation) do
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
