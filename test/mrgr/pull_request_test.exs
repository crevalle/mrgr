defmodule Mrgr.PullRequestTest do
  use Mrgr.DataCase

  describe "paged_pending_pull_requests/2" do
    setup :with_repos

    test "loads open prs for the current installation", ctx do
      _closed = insert!(:pull_request, status: "closed", repository: ctx.r1)

      recent = Mrgr.DateTime.shift_from_now(-60, :second)
      two_days_ago = Mrgr.DateTime.shift_from_now(-2, :day)

      recently_opened = insert!(:pull_request, opened_at: recent, repository: ctx.r1)
      two_days = insert!(:pull_request, opened_at: two_days_ago, repository: ctx.r2)

      # other installation
      page = Mrgr.PullRequest.paged_pending_pull_requests(98289)
      assert page.total_entries == 0

      page = Mrgr.PullRequest.paged_pending_pull_requests(ctx.i.id, %{page_size: 1})

      assert page.total_entries == 2
      assert Enum.count(page.entries) == 1

      page =
        Mrgr.PullRequest.paged_pending_pull_requests(ctx.i.id, %{
          since: Mrgr.DateTime.shift_from_now(-14, :day)
        })

      assert_list_of_structs_equal(page.entries, [recently_opened, two_days])

      %{entries: [e]} =
        Mrgr.PullRequest.paged_pending_pull_requests(ctx.i.id, %{
          since: Mrgr.DateTime.shift_from_now(-14, :day),
          before: Mrgr.DateTime.shift_from_now(-1, :day)
        })

      assert e.id == two_days.id
    end
  end

  describe "paged_needs_approval_prs" do
    setup :with_repos

    test "returns prs that are not fully approved", ctx do
      pull_request = insert!(:pull_request, repository: ctx.r1)

      user = %{current_installation_id: ctx.i.id}

      %{entries: [e], total_entries: total} = Mrgr.PullRequest.paged_needs_approval_prs(user)

      assert total == 1
      assert e.id == pull_request.id
    end

    test "does not return prs that need no approvals", ctx do
      settings = build(:repository_settings, required_approving_review_count: 0)
      repo = insert!(:repository, installation: ctx.i, settings: settings)

      _pull_request = insert!(:pull_request, repository: repo)

      user = %{current_installation_id: ctx.i.id}

      %{entries: e} = Mrgr.PullRequest.paged_needs_approval_prs(user)

      assert Enum.empty?(e)
    end
  end

  describe "paged_ready_to_merge_prs" do
    setup :with_repos

    test "returns prs that need no approvals", ctx do
      settings = build(:repository_settings, required_approving_review_count: 0)
      repo = insert!(:repository, installation: ctx.i, settings: settings)

      pull_request = insert!(:pull_request, repository: repo)

      user = %{current_installation_id: ctx.i.id}

      %{entries: [e]} = Mrgr.PullRequest.paged_ready_to_merge_prs(user)

      assert e.id == pull_request.id
    end

    test "returns prs that are fully approved", ctx do
      _unapproved = insert!(:pull_request, repository: ctx.r1)

      approved = insert!(:pull_request, repository: ctx.r1)
      _approving_review = insert!(:pr_review, pull_request: approved)
      _approving_review = insert!(:pr_review, pull_request: approved)

      user = %{current_installation_id: ctx.i.id}

      %{entries: [e]} = Mrgr.PullRequest.paged_ready_to_merge_prs(user)

      assert e.id == approved.id
    end

    test "returns PRs that do not require approvals", ctx do
      settings = build(:repository_settings, required_approving_review_count: 0)
      repo = insert!(:repository, installation: ctx.i, settings: settings)
      pr = insert!(:pull_request, repository: repo)

      user = %{current_installation_id: ctx.i.id}

      %{entries: [e]} = Mrgr.PullRequest.paged_ready_to_merge_prs(user)

      assert e.id == pr.id
    end

    test "returns prs that are either passing or running CI", ctx do
      failing = insert!(:pull_request, ci_status: "failing", repository: ctx.r1)
      passing = insert!(:pull_request, ci_status: "success", repository: ctx.r1)
      building = insert!(:pull_request, ci_status: "running", repository: ctx.r1)

      _approving_review = insert!(:pr_review, pull_request: passing)
      _approving_review = insert!(:pr_review, pull_request: building)
      _approving_review = insert!(:pr_review, pull_request: failing)

      user = %{current_installation_id: ctx.i.id}

      %{entries: [p, b]} = Mrgr.PullRequest.paged_ready_to_merge_prs(user)

      assert p.id == passing.id
      assert b.id == building.id
    end
  end

  describe "fix_ci" do
    setup :with_repos

    test "returns approved and unapproved PRs that need CI fixed", ctx do
      _socks = insert!(:pull_request, repository: ctx.r1)
      unapproved = insert!(:pull_request, repository: ctx.r1, ci_status: "failure")
      approved = insert!(:pull_request, repository: ctx.r1, ci_status: "failure")
      _approving_review = insert!(:pr_review, pull_request: approved)

      user = %{current_installation_id: ctx.i.id}

      %{entries: [u, a]} = Mrgr.PullRequest.paged_fix_ci_prs(user)

      assert u.id == unapproved.id
      assert a.id == approved.id
    end
  end

  defp with_repos(_ctx) do
    i = insert!(:installation)
    r1 = insert!(:repository, installation: i)
    r2 = insert!(:repository, installation: i)

    %{i: i, r1: r1, r2: r2}
  end
end
