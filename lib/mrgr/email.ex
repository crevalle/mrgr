defmodule Mrgr.Email do
  use Phoenix.VerifiedRoutes, endpoint: MrgrWeb.Endpoint, router: MrgrWeb.Router

  import MrgrWeb.Formatter, only: [account_name: 1]
  import Swoosh.Email

  def invite_user_to_installation(recipient, installation) do
    assigns = %{
      installation: installation
    }

    new()
    |> from({"Mrgr", "noreply@mrgr.io"})
    |> to(recipient)
    |> subject("You've been invited to join #{account_name(installation)} on Mrgr")
    |> render_with_layout(MrgrWeb.Email.Renderer.invite_user_to_installation(assigns))
  end

  def hif_alert(alerts, recipient, pull_request_id, repository) do
    url = url(MrgrWeb.Endpoint, ~p"/pull-requests/hifs/#{pull_request_id}/files-changed")

    assigns = %{
      hif_alerts: alerts,
      repository_name: repository.name,
      url: url
    }

    new()
    |> from({"Mrgr", "noreply@mrgr.io"})
    |> to(recipient)
    |> subject("File Change Alert in #{assigns.repository_name}")
    |> render_with_layout(MrgrWeb.Email.Renderer.hif_alert(assigns))
  end

  def send_changelog(pull_requests, last_week_count, recipient) do
    changelog = __MODULE__.Changelog.new(pull_requests)

    assigns = %{
      pull_requests: changelog,
      closed_last_week_count: last_week_count,
      recipient: recipient
    }

    new()
    |> from({"Mrgr", "noreply@mrgr.io"})
    |> to(recipient)
    |> subject("Weekly Merged Pull Request Summary - #{changelog.total}")
    |> render("weekly_changelog", assigns)
  end

  def render(email, template, assigns) do
    rendered = apply(MrgrWeb.Email.Renderer, String.to_existing_atom(template), [assigns])
    render_with_layout(email, rendered)
  end

  defp render_with_layout(email, heex) do
    html_body(
      email,
      render_component(MrgrWeb.Email.Renderer.layout(%{email: email, inner_content: heex}))
    )
  end

  defp render_component(heex) do
    heex |> Phoenix.HTML.Safe.to_iodata() |> IO.chardata_to_string()
  end

  defmodule Changelog do
    def new(pull_requests) do
      bucket =
        Enum.reduce(pull_requests, build_bucket(), fn pr, acc ->
          acc
          |> increment_total()
          |> maybe_put_high_impact(pr)
          |> put_pr_in_date_bucket(pr)
        end)

      bucket
      |> put_last_week_keys()
      |> put_this_week_key()
    end

    def build_bucket do
      basic = %{
        total: 0,
        high_impact: [],
        now: DateTime.now!("America/Los_Angeles") |> DateTime.to_date()
      }

      add_date_keys(basic, 0..-7)
    end

    def add_date_keys(bucket, range) do
      Enum.reduce(range, bucket, fn d, acc ->
        # %{
        # ~D[2023-02-19] => [],
        # ~D[2023-02-20] => [],
        # ~D[2023-02-21] => [],
        # ~D[2023-02-22] => [],
        # ~D[2023-02-23] => []
        # }
        key = key_from_offset(bucket, d)
        Map.put(acc, key, [])
      end)
    end

    def put_this_week_key(bucket) do
      # ordered by day of week, Monday first
      this_week =
        Enum.map(-4..0, fn day_offset ->
          key = key_from_offset(bucket, day_offset)
          pull_requests = Map.get(bucket, key)

          %{date: key, pull_requests: pull_requests}
        end)

      Map.put(bucket, :this_week, this_week)
    end

    def put_last_week_keys(bucket) do
      last_week = %{
        last_friday: -7,
        saturday: -6,
        sunday: -5
      }

      Enum.reduce(last_week, bucket, fn {day_name, day_offset}, acc ->
        key = key_from_offset(acc, day_offset)
        pull_requests = Map.get(acc, key)

        Map.put(acc, day_name, %{date: key, pull_requests: pull_requests})
      end)
    end

    def maybe_put_high_impact(bucket, pr) do
      case high_impact?(pr) do
        true ->
          hi_prs = [pr | bucket.high_impact]
          %{bucket | high_impact: hi_prs}

        false ->
          bucket
      end
    end

    def put_pr_in_date_bucket(bucket, pr) do
      key =
        pr.merged_at
        |> DateTime.shift_zone!("America/Los_Angeles")
        |> DateTime.to_date()

      prs = Map.get(bucket, key)

      Map.put(bucket, key, [pr | prs])
    end

    def increment_total(bucket) do
      %{bucket | total: bucket.total + 1}
    end

    defp key_from_offset(bucket, offset) do
      # offset should be negative
      Date.add(bucket.now, offset)
    end

    defp high_impact?(pr) do
      Enum.any?(pr.high_impact_file_rules)
    end
  end
end
