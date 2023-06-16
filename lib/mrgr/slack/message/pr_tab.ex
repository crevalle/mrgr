defmodule Mrgr.Slack.Message.PRTab do
  use Mrgr.Slack.Message

  def render(pull_request, tab) do
    %{
      text: "PR opened matching '#{tab.title}'",
      blocks: [
        header("PR opened matching '#{tab.title}'"),
        section(body(pull_request, tab)),
        actions(button("View it on Github", github_url(pull_request)))
      ]
    }
  end

  def body(pull_request, tab) do
    # can't get jump links to work, but they'd be nice.
    path = ~p"/pull-requests/#{tab.permalink}"
    mrgr_url = "#{MrgrWeb.Endpoint.url()}#{path}"

    "#{author_handle(pull_request)} opened #{build_link(mrgr_url, pull_request.title)} in the *#{pull_request.repository.name}* repository that matched your *#{tab.title}* custom filter."
  end
end
