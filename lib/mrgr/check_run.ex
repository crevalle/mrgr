defmodule Mrgr.CheckRun do
  # def process(%{"action" => requested, "check_suite" => data}) do

  # end
  #
  def create(payload) do
    external_id = payload["installation"]["id"]
    installation = Mrgr.Installation.find_by_external_id(external_id)

    client = Mrgr.Github.Client.new(installation)

    head = payload["after"]

    socks(client, head)
  end

  def socks(client, head) do
    path = "repos/crevalle/mrgr/check-runs"

    data = %{
      name: "Mrgr Checklist",
      head_sha: head,
      details_url: "https://socks.com"
    }

    Tentacat.post(path, client, data)
    |> IO.inspect(label: "check run created response")

    # associate check run with PM

    # Mrgr.Github.parse_into(response, Mrgr.Github.User)
  end

  def complete(client, check_run_id) do
    path = "repos/crevalle/mrgr/check-runs/#{check_run_id}"
    # Conclusion Required if you provide completed_at or a status of completed.
    # The final conclusion of the check.
    # Can be one of action_required, cancelled, failure, neutral, success, skipped, stale, or timed_out.
    # Note: Providing conclusion will automatically set the status parameter to completed.
    # You cannot change a check run conclusion to stale, only GitHub can set this.
    data = %{
      conclusion: "success",
      completed_at: DateTime.utc_now()
    }

    Tentacat.patch(path, client, data)
  end
end
