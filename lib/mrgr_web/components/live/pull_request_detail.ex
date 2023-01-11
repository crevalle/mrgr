defmodule MrgrWeb.Components.Live.PullRequestDetail do
  use MrgrWeb, :live_component
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.PullRequest
end
