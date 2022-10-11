defmodule MrgrWeb.Components.ActivityComponent do
  use MrgrWeb, :component
  use Mrgr.PubSub.Event

  @translated_merge_actions %{
    "synchronize" => "updated"
  }

  # i don't know what the other events will look like
  # for now this just handles the raw webhook payload, without the obj data
  #
  # need to figure out how to store the activity stream - what will i use it for? just webhooks?
  # want to link to a relevant page
  def render(%{event: "merge:" <> action, payload: _} = assigns) do
    assigns =
      assigns
      |> assign(:action, action)

    ~H"""
    <.event avatar_url={@payload.user.avatar_url} name={@payload.user.login} at={at(@payload)} >
      <:description>
        <%= translate_merge_action(@action) %> <%= @payload.title %>
      </:description>

      <:icon>
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M12 7a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0V8.414l-4.293 4.293a1 1 0 01-1.414 0L8 10.414l-4.293 4.293a1 1 0 01-1.414-1.414l5-5a1 1 0 011.414 0L11 10.586 14.586 7H12z" clip-rule="evenodd" />
        </svg>
      </:icon>

      <:detail>
        <%= MrgrWeb.Components.Merge.file_change_badges(%{merge: @payload}) %>
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

      <:icon>
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path d="M15 8a3 3 0 10-2.977-2.63l-4.94 2.47a3 3 0 100 4.319l4.94 2.47a3 3 0 10.895-1.789l-4.94-2.47a3.027 3.027 0 000-.74l4.94-2.47C13.456 7.68 14.19 8 15 8z" />
        </svg>
      </:icon>
      <:detail>
        <%= @payload["head_commit"]["message"] %>
      </:detail>
    </.event>
    """
  end

  def event(assigns) do
    ~H"""
    <li class="p-2">
      <div class="flex space-x-3">
        <div class="flex flex-col space-y-1">
          <img class="h-6 w-6 rounded-full" src={"#{@avatar_url}"} alt="">
          <p class="text-sm text-gray-500"><%= render_slot(@icon) %></p>
        </div>
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
    default = String.replace(action, "_", " ")
    Map.get(@translated_merge_actions, action, default)
  end
end
