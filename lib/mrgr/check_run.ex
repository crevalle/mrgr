defmodule Mrgr.CheckRun do

  def process(%{"action" => requested, "check_suite" => data}) do

  end

  def socks(token) do
    client = Tentacat.Client.new(%{access_token: token})
    path = "repos/crevalle/mrgr/check-runs"
    data = %{
      name: "Mrgr Checklist",
      head_sha:  "7b59ed472bf633bb2137db1b8141b21b1448675c",
      details_url: "https://socks.com"
    }
    Tentacat.post(path, client, data)
    # Mrgr.Github.parse_into(response, Mrgr.Github.User)
  end

  def complete(check_run_id, token) do
    client = Tentacat.Client.new(%{access_token: token})
    path = "repos/crevalle/mrgr/check-runs/#{check_run_id}"
    # Conclusion Required if you provide completed_at or a status of completed.
      # The final conclusion of the check.
      # Can be one of action_required, cancelled, failure, neutral, success, skipped, stale, or timed_out.
      # Note: Providing conclusion will automatically set the status parameter to completed.
      # You cannot change a check run conclusion to stale, only GitHub can set this.
    data = %{
      conclusion: "success",
      completed_at: DateTime.utc_now
    }
    Tentacat.patch(path, client, data)

  end
end
