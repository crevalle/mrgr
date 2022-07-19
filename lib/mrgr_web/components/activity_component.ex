defmodule MrgrWeb.Components.ActivityComponent do
  use MrgrWeb, :component

  # i don't know what the other events will look like
  # for now this just handles the raw webhook payload, without the obj data
  #
  # need to figure out how to store the activity stream - what will i use it for? just webhooks?
  # want to link to a relevant page
  def render(%{event: event} = assigns) do
    ~H"""
    <li><%= format_ref(@event["ref"]) %> updated to <%= shorten_sha(@event["after"]) %></li>
    """
  end

  def format_ref("refs/heads/" <> name), do: name
end
