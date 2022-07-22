defmodule MrgrWeb.Components.ActivityComponent do
  use MrgrWeb, :component
  use Mrgr.PubSub.Event

  @translated_merge_actions %{
    "synchronized" => "updated"
  }

  # i don't know what the other events will look like
  # for now this just handles the raw webhook payload, without the obj data
  #
  # need to figure out how to store the activity stream - what will i use it for? just webhooks?
  # want to link to a relevant page
  def render(%{event: "merge:" <> action, payload: _} = assigns) do
    ~H"""
    <.event avatar_url={@payload.user.avatar_url} name={@payload.user.login} at={at(@payload)} >
      <:description>
        <%= translate_merge_action(action) %> <%= @payload.title %>
      </:description>

      <:detail>
        <%= MrgrWeb.Component.PendingMerge.change_badges(%{merge: @payload}) %>
      </:detail>
    </.event>
    """
  end

  def render(%{event: @branch_pushed, payload: _} = assigns) do
    ~H"""
    <.event avatar_url={@payload["sender"]["avatar_url"]} name={@payload["sender"]["login"]} at={at(@payload)}>
      <:description>
        pushed <%= shorten_sha(@payload["after"]) %> to <%= ref(@payload["ref"]) %>
      </:description>

      <:detail>
        <%= @payload["head_commit"]["message"] %>
      </:detail>
    </.event>
    """
  end

  def event(assigns) do
    ~H"""
    <li class="py-4">
      <div class="flex space-x-3">
        <img class="h-6 w-6 rounded-full" src={"#{@avatar_url}"} alt="">
        <div class="flex-1 space-y-1">
          <div class="flex items-center justify-between">
            <h3 class="text-sm font-medium"><%= @name %></h3>
            <p class="text-sm text-gray-500"><%= @at %></p>
          </div>
          <p class="text-sm text-gray-500"><%= render_slot(@description) %></p>
          <p class="text-sm text-gray-500"><%= render_slot(@detail) %></p>
        </div>
      </div>
    </li>
    """
  end

  def at(%Mrgr.Schema.Merge{} = merge) do
    ago(Mrgr.Schema.Merge.head_committed_at(merge))
  end

  def at(branch_webhook) do
    ago(Mrgr.Branch.head_committed_at(branch_webhook))
  end

  defp translate_merge_action(action) do
    Map.get(@translated_merge_actions, action, action)
  end
end
