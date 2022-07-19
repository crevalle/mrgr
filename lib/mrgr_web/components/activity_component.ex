defmodule MrgrWeb.Components.ActivityComponent do
  use MrgrWeb, :component

  # i don't know what the other events will look like
  # for now this just handles the raw webhook payload, without the obj data
  #
  # need to figure out how to store the activity stream - what will i use it for? just webhooks?
  # want to link to a relevant page
  def render(%{event: "merge:synchronized", payload: _} = assigns) do
    ~H"""
    <li>PR <%= @payload.title %> updated </li>
    """
  end

  def render(%{event: "merge:created", payload: _} = assigns) do
    ~H"""
    <li>PR <%= @payload.title %> opened </li>
    """
  end

  def render(%{event: "branch:pushed", payload: _} = assigns) do
    ~H"""
    <li><%= format_ref(@payload["ref"]) %> updated to <%= shorten_sha(@payload["after"]) %></li>
    """
  end

  def format_ref("refs/heads/" <> name), do: name
end
