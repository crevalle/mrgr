defmodule Mrgr.Slack.Helpers do


  def github_url(%Mrgr.Schema.PullRequest{} = pr) do
    Mrgr.Schema.PullRequest.external_url(pr)
  end
end
