defmodule Mrgr.Slack.Message do
  use Phoenix.VerifiedRoutes, endpoint: MrgrWeb.Endpoint, router: MrgrWeb.Router
  import MrgrWeb.Formatter

  def compose_hif_message(rules, pull_request) do
    repo_name = pull_request.repository.name

    %{
      text: "❗️High Impact File Change in #{repo_name}",
      blocks: [
        %{
          type: "header",
          text: %{
            type: "plain_text",
            text: "High Impact File Change in #{repo_name}"
          }
        },
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: hif_body(pull_request)
          }
        },
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: hif_list(rules)
          }
        },
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: footer(pull_request)
          }
        }
      ]
    }
  end

  def hif_body(pull_request) do
    mrgr_url =
      "#{MrgrWeb.Endpoint.url()}#{~p"/pull-requests/hifs/#{pull_request.id}/files-changed"}"

    author_handle = "@#{login(pull_request.author)}"

    "#{author_handle} opened #{build_link(mrgr_url, pull_request.title)} in the *#{pull_request.repository.name}* repository with the following High Impact Changes:"
  end

  def footer(pull_request) do
    github_url = Mrgr.Schema.PullRequest.external_url(pull_request)
    build_link(github_url, "View it on Github")
  end

  defp build_link(url, text) do
    "<#{url}|#{text}>"
  end

  defp hif_list(rules) do
    for rule <- rules, filename <- rule.filenames do
      hif_entry(rule, filename)
    end
    |> Enum.join("\n")
  end

  defp hif_entry(rule, filename) do
    "• *[#{rule.name}]* `#{filename}`"
  end
end
