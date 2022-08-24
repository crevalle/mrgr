defmodule Mrgr.CheckRun do
  # def process(%{"action" => requested, "check_suite" => data}) do

  # end
  #
  # def create(payload) do
  # external_id = payload["installation"]["id"]
  # installation = Mrgr.Installation.find_by_external_id(external_id)

  # client = Mrgr.Github.Client.new(installation)

  # head = payload["after"]

  # socks(client, head)
  # end

  def create(client, owner, repo, head) do
    body = %{
      name: "Mrgr Merge Freeze",
      head_sha: head,
      status: "completed",
      conclusion: "success",
      details_url: "https://socks.com"
    }

    Tentacat.post("repos/#{owner}/#{repo}/check-runs", client, body)

    # associate check run with PM

    # Mrgr.Github.parse_into(response, Mrgr.Github.User)
  end

  def update(client, owner, repo, check_run_id, opts) do
    # Conclusion Required if you provide completed_at or a status of completed.
    # The final conclusion of the check.
    # Can be one of action_required, cancelled, failure, neutral, success, skipped, stale, or timed_out.
    # Note: Providing conclusion will automatically set the status parameter to completed.
    # You cannot change a check run conclusion to stale, only GitHub can set this.
    body = %{
      conclusion: opts[:conclusion],
      completed_at: opts[:completed_at]
    }

    Tentacat.patch("repos/#{owner}/#{repo}/check-runs/#{check_run_id}", client, body)
  end
end
