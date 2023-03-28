defmodule Mrgr.PullRequestTest do
  use Mrgr.DataCase

  # describe "paged_pending_pull_requests/2" do
  # setup :with_repos

  # test "loads open prs for the current installation", ctx do
  # _closed = insert!(:pull_request, status: "closed", repository: ctx.r1)

  # recent = Mrgr.DateTime.shift_from_now(-60, :second)
  # two_days_ago = Mrgr.DateTime.shift_from_now(-2, :day)

  # recently_opened = insert!(:pull_request, opened_at: recent, repository: ctx.r1)
  # two_days = insert!(:pull_request, opened_at: two_days_ago, repository: ctx.r2)

  # # other installation
  # page = Mrgr.PullRequest.paged_pending_pull_requests(98289)
  # assert page.total_entries == 0

  # page = Mrgr.PullRequest.paged_pending_pull_requests(ctx.i.id, %{page_size: 1})

  # assert page.total_entries == 2
  # assert Enum.count(page.entries) == 1

  # page =
  # Mrgr.PullRequest.paged_pending_pull_requests(ctx.i.id, %{
  # since: Mrgr.DateTime.shift_from_now(-14, :day)
  # })

  # assert_list_of_structs_equal(page.entries, [recently_opened, two_days])

  # %{entries: [e]} =
  # Mrgr.PullRequest.paged_pending_pull_requests(ctx.i.id, %{
  # since: Mrgr.DateTime.shift_from_now(-14, :day),
  # before: Mrgr.DateTime.shift_from_now(-1, :day)
  # })

  # assert e.id == two_days.id
  # end
  # end

  # describe "needs_approval_prs" do
  # setup :with_repos

  # test "returns prs that are not fully approved", ctx do
  # pull_request = insert!(:pull_request, repository: ctx.r1)

  # user = %{current_installation_id: ctx.i.id}

  # [pr] = Mrgr.PullRequest.needs_approval_prs(user)

  # assert pr.id == pull_request.id
  # end

  # test "does not return prs that need no approvals", ctx do
  # settings = build(:repository_settings, required_approving_review_count: 0)
  # repo = insert!(:repository, installation: ctx.i, settings: settings)

  # _pull_request = insert!(:pull_request, repository: repo)

  # user = %{current_installation_id: ctx.i.id}

  # prs = Mrgr.PullRequest.needs_approval_prs(user)

  # assert Enum.empty?(prs)
  # end
  # end

  describe "dormant_prs/1" do
    setup [:with_repos, :with_dormancy_periods]

    test "returns PRs that have no activity within the dormancy period", ctx do
      # dormancy is 24 < now < 48 hours ago.  so anything between 1 and 3 days old

      _fresh_pr = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.fresh)
      dormant_pr = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.dormant)
      also_dormant_pr = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.also_dormant)
      _stale_pr = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)

      pr_ids = Mrgr.PullRequest.dormant_prs(ctx.user) |> ids()

      assert Enum.count(pr_ids) == 2
      assert Enum.member?(pr_ids, dormant_pr.id)
      assert Enum.member?(pr_ids, also_dormant_pr.id)
    end

    test "accounts for comments in the dormancy period", ctx do
      # stale prs to exercise the comment logic
      pr_1 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:comment, pull_request: pr_1, posted_at: ctx.fresh)

      pr_2 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:comment, pull_request: pr_2, posted_at: ctx.dormant)

      pr_3 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:comment, pull_request: pr_3, posted_at: ctx.also_dormant)

      pr_4 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:comment, pull_request: pr_4, posted_at: ctx.stale)

      # dormant opened at should be overruled by fresh comment
      pr_5 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.dormant)
      insert!(:comment, pull_request: pr_5, posted_at: ctx.fresh)

      # make sure you're checking the most recent comment
      pr_6 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:comment, pull_request: pr_6, posted_at: ctx.fresh)
      insert!(:comment, pull_request: pr_6, posted_at: ctx.dormant)

      pr_ids = Mrgr.PullRequest.dormant_prs(ctx.user) |> ids()

      assert Enum.count(pr_ids) == 2
      assert Enum.member?(pr_ids, pr_2.id)
      assert Enum.member?(pr_ids, pr_3.id)
    end

    test "accounts for commits in dormancy period", ctx do
      fresh_commit = build(:commit, author: build(:git_actor, date: ctx.fresh))
      dormant_commit = build(:commit, author: build(:git_actor, date: ctx.dormant))
      also_dormant_commit = build(:commit, author: build(:git_actor, date: ctx.also_dormant))
      stale_commit = build(:commit, author: build(:git_actor, date: ctx.stale))

      # stale prs to exercise the commit logic
      insert!(:pull_request, commits: [fresh_commit], repository: ctx.r1, opened_at: ctx.stale)

      pr_2 =
        insert!(:pull_request, commits: [dormant_commit], repository: ctx.r1, opened_at: ctx.stale)

      pr_3 =
        insert!(:pull_request,
          commits: [also_dormant_commit],
          repository: ctx.r1,
          opened_at: ctx.stale
        )

      insert!(:pull_request, commits: [stale_commit], repository: ctx.r1, opened_at: ctx.stale)

      # dormant opened at should be overruled by fresh commit
      insert!(:pull_request, commits: [fresh_commit], repository: ctx.r1, opened_at: ctx.dormant)

      # make sure you're checking the most recent commit
      insert!(:pull_request,
        commits: [stale_commit, fresh_commit],
        repository: ctx.r1,
        opened_at: ctx.stale
      )

      pr_ids = Mrgr.PullRequest.dormant_prs(ctx.user) |> ids()

      assert Enum.count(pr_ids) == 2
      assert Enum.member?(pr_ids, pr_2.id)
      assert Enum.member?(pr_ids, pr_3.id)
    end

    test "accounts for pr_reviews in the dormancy period", ctx do
      # stale prs to exercise the pr_review logic
      pr_1 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:pr_review, pull_request: pr_1, submitted_at: ctx.fresh)

      pr_2 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:pr_review, pull_request: pr_2, submitted_at: ctx.dormant)

      pr_3 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:pr_review, pull_request: pr_3, submitted_at: ctx.also_dormant)

      pr_4 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:pr_review, pull_request: pr_4, submitted_at: ctx.stale)

      # dormant opened at should be overruled by fresh pr_review
      pr_5 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.dormant)
      insert!(:pr_review, pull_request: pr_5, submitted_at: ctx.fresh)

      # make sure you're checking the most recent pr_review
      pr_6 = insert!(:pull_request, repository: ctx.r1, opened_at: ctx.stale)
      insert!(:pr_review, pull_request: pr_6, submitted_at: ctx.fresh)
      insert!(:pr_review, pull_request: pr_6, submitted_at: ctx.dormant)

      pr_ids = Mrgr.PullRequest.dormant_prs(ctx.user) |> ids() |> IO.inspect()

      assert Enum.count(pr_ids) == 2
      assert Enum.member?(pr_ids, pr_2.id)
      assert Enum.member?(pr_ids, pr_3.id)
    end
  end

  # describe "paged_ready_to_merge_prs" do
  # setup :with_repos

  # test "returns prs that need no approvals", ctx do
  # settings = build(:repository_settings, required_approving_review_count: 0)
  # repo = insert!(:repository, installation: ctx.i, settings: settings)

  # pull_request = insert!(:pull_request, repository: repo)

  # user = %{current_installation_id: ctx.i.id}

  # %{entries: [e]} = Mrgr.PullRequest.paged_ready_to_merge_prs(user)

  # assert e.id == pull_request.id
  # end

  # test "returns prs that are fully approved", ctx do
  # _unapproved = insert!(:pull_request, repository: ctx.r1)

  # approved = insert!(:pull_request, repository: ctx.r1)
  # _approving_review = insert!(:pr_review, pull_request: approved)
  # _approving_review = insert!(:pr_review, pull_request: approved)

  # user = %{current_installation_id: ctx.i.id}

  # %{entries: [e]} = Mrgr.PullRequest.paged_ready_to_merge_prs(user)

  # assert e.id == approved.id
  # end

  # test "returns PRs that do not require approvals", ctx do
  # settings = build(:repository_settings, required_approving_review_count: 0)
  # repo = insert!(:repository, installation: ctx.i, settings: settings)
  # pr = insert!(:pull_request, repository: repo)

  # user = %{current_installation_id: ctx.i.id}

  # %{entries: [e]} = Mrgr.PullRequest.paged_ready_to_merge_prs(user)

  # assert e.id == pr.id
  # end

  # test "returns prs that are either passing or running CI", ctx do
  # failing = insert!(:pull_request, ci_status: "failing", repository: ctx.r1)
  # passing = insert!(:pull_request, ci_status: "success", repository: ctx.r1)
  # building = insert!(:pull_request, ci_status: "running", repository: ctx.r1)

  # _approving_review = insert!(:pr_review, pull_request: passing)
  # _approving_review = insert!(:pr_review, pull_request: building)
  # _approving_review = insert!(:pr_review, pull_request: failing)

  # user = %{current_installation_id: ctx.i.id}

  # %{entries: [p, b]} = Mrgr.PullRequest.paged_ready_to_merge_prs(user)

  # assert p.id == passing.id
  # assert b.id == building.id
  # end
  # end

  # describe "fix_ci" do
  # setup :with_repos

  # test "returns approved and unapproved PRs that need CI fixed", ctx do
  # _socks = insert!(:pull_request, repository: ctx.r1)
  # unapproved = insert!(:pull_request, repository: ctx.r1, ci_status: "failure")
  # approved = insert!(:pull_request, repository: ctx.r1, ci_status: "failure")
  # _approving_review = insert!(:pr_review, pull_request: approved)

  # user = %{current_installation_id: ctx.i.id}

  # %{entries: [u, a]} = Mrgr.PullRequest.paged_fix_ci_prs(user)

  # assert u.id == unapproved.id
  # assert a.id == approved.id
  # end
  # end

  defp with_repos(_ctx) do
    i = insert!(:installation)
    r1 = insert!(:repository, installation: i)
    r2 = insert!(:repository, installation: i)

    user = insert!(:user, current_installation: i)

    # make the repos visible on the dashboard
    insert!(:user_visible_repository, user: user, repository: r1)
    insert!(:user_visible_repository, user: user, repository: r2)

    %{i: i, r1: r1, r2: r2, user: user}
  end

  defp with_dormancy_periods(_ctx) do
    fresh =
      Mrgr.DateTime.now()
      |> DateTime.add(-3, :hour)
      |> Mrgr.DateTime.safe_truncate()

    dormant =
      Mrgr.DateTime.now()
      |> DateTime.add(-25, :hour)
      |> Mrgr.DateTime.safe_truncate()

    also_dormant =
      Mrgr.DateTime.now()
      |> DateTime.add(-49, :hour)
      |> Mrgr.DateTime.safe_truncate()

    stale =
      Mrgr.DateTime.now()
      |> DateTime.add(-73, :hour)
      |> Mrgr.DateTime.safe_truncate()

    %{fresh: fresh, dormant: dormant, also_dormant: also_dormant, stale: stale}
  end
end
