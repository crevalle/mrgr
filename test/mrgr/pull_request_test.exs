defmodule Mrgr.PullRequestTest do
  use Mrgr.DataCase

  describe "paged_pending_pull_requests/2" do
    test "loads open prs for the current installation" do
      i = insert!(:installation)
      r1 = insert!(:repository, installation: i)
      r2 = insert!(:repository, installation: i)

      _closed = insert!(:pull_request, status: "closed", repository: r1)

      recent = Mrgr.DateTime.shift_from_now(-60, :second)
      two_days_ago = Mrgr.DateTime.shift_from_now(-2, :day)

      recently_opened = insert!(:pull_request, opened_at: recent, repository: r1)
      two_days = insert!(:pull_request, opened_at: two_days_ago, repository: r2)

      # other installation
      page = Mrgr.PullRequest.paged_pending_pull_requests(98289)
      assert page.total_entries == 0

      page = Mrgr.PullRequest.paged_pending_pull_requests(i.id, %{page_size: 1})

      assert page.total_entries == 2
      assert Enum.count(page.entries) == 1

      page =
        Mrgr.PullRequest.paged_pending_pull_requests(i.id, %{
          since: Mrgr.DateTime.shift_from_now(-14, :day)
        })

      assert_list_of_structs_equal(page.entries, [recently_opened, two_days])

      %{entries: [e]} =
        Mrgr.PullRequest.paged_pending_pull_requests(i.id, %{
          since: Mrgr.DateTime.shift_from_now(-14, :day),
          before: Mrgr.DateTime.shift_from_now(-1, :day)
        })

      assert e.id == two_days.id
    end
  end
end
