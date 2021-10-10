defmodule Mrgr.CheckRun do

  # def process(%{"action" => requested, "check_suite" => data}) do

  # end
  #
  def create(payload) do
    installation_id = payload["installation"]["id"]
    at = Mrgr.Installation.create_access_token(%{external_id: installation_id})

    head = payload["after"]

    socks(at.token, head)
  end

  def socks(token, head) do
    client = Tentacat.Client.new(%{access_token: token})
    path = "repos/crevalle/mrgr/check-runs"
    data = %{
      name: "Mrgr Checklist",
      head_sha: head,
      details_url: "https://socks.com"
    }
    Tentacat.post(path, client, data)
    |> IO.inspect(label: "check run created response")
    # Mrgr.Github.parse_into(response, Mrgr.Github.User)
  end

  def complete(token, check_run_id) do
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
