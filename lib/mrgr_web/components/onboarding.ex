defmodule MrgrWeb.Components.Onboarding do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  import MrgrWeb.Components.Core

  attr :name, :string
  attr :installation, :map
  attr :number, :integer
  attr :stats, :map, default: %{}

  slot :inner_block, default: nil

  def install_github_app(assigns) do
    assigns = set_status(assigns)

    ~H"""
    <.step_option status={@status}>
      <:number><%= @step %></:number>
      <:title>
        Install our Github App
      </:title>

      <:description>
        This is how we pull in your pull request data and stay up to date.  Requires admin privileges on your organization.
      </:description>

      <.install_action installation={@state.installation} />
    </.step_option>
    """
  end

  def sync_data(assigns) do
    # class =
    # case assigns.installation do
    # nil ->
    # todo()

    # i ->
    # case i.state do
    # "created" -> todo()
    # "onboarding_complete" -> done()
    # _the_midst_of_onboarding -> in_progress()
    # end
    # end

    assigns = set_status(assigns)

    ~H"""
    <.step_option status={@status}>
      <:number><%= @step %></:number>
      <:title>
        Sync your data
      </:title>

      <%= if @status == :todo do %>
        <p class="text-gray-500">We'll do this for you once the app is installed :)</p>
      <% else %>
        <.syncing_message installation={@state.installation} />
        <.render_stats stats={@state.stats} />
      <% end %>
    </.step_option>
    """
  end

  def review_pr_notifications(assigns) do
    assigns = set_status(assigns)

    alerts = [
      "PRs assigned to me",
      "Controversial PRs",
      "Weekly Changelog",
      "PRs with migrations",
      "PRs with dependency changes",
      "PRs with API changes"
    ]

    assigns =
      assigns
      |> assign(:alerts, alerts)

    ~H"""
    <.step_option status={@status}>
      <:number><%= @step %></:number>
      <:title>Review PR Alerts</:title>

      <div class="flex flex-col space-y-4">
        <%= if @status != :todo do %>
          <p>We've created the following default alerts for you:</p>
          <.ul>
            <.icon_li :for={alert <- @alerts}>
              <:icon>
                <.i name="check-circle" class="text-teal-700" />
              </:icon>
              <%= alert %>
            </.icon_li>
          </.ul>
        <% end %>

        <%= if @status == :in_progress do %>
          <p>How would you like to receive them?</p>
          <.button_group>
            <.l phx-click="notify-via-email" class="btn btn-primary">Email Me</.l>
            <div class="flex flex-col space-y-1 items-center">
              <.slack_button user_id={@state.user.id}>Via Slack</.slack_button>
              <p class="text-xs text-gray-500 text-center w-64">
                Click this button to install the MrgrBot to your Slack workspace.
              </p>
            </div>
          </.button_group>
        <% end %>

        <%= if @status == :done do %>
          <%= if @state.installation.slackbot do %>
            <.col class="space-y-1">
              <.slack_connected />
              <p class="text-gray-500">You will receive all alerts via Slack.</p>
            </.col>
          <% else %>
            <.col>
              <p>
                👍 OK! We'll notify you at <span class="font-semibold"><%= @state.user.email %></span>.
              </p>
              <p class="text-gray-500 text-sm">
                You can change your email or install our Slackbot on your Profile page.
              </p>
            </.col>
          <% end %>
        <% end %>
      </div>
    </.step_option>
    """
  end

  def get_to_it(assigns) do
    assigns = set_status(assigns)

    ~H"""
    <.step_option status={@status}>
      <:number><%= @step %></:number>
      <:title>
        You're done! 🏁
      </:title>

      <%= if @status == :in_progress do %>
        <.col class="space-y-4">
          <.onboarding_complete_message organization?={organization?(@state.installation)} />

          <.button_group>
            <.l phx-click="add-more-alerts" class="btn btn-primary">Add More File Alerts</.l>
            <.l phx-click="go-to-dashboard" class="btn btn-secondary">View Open PRs</.l>
          </.button_group>
        </.col>
      <% end %>
    </.step_option>
    """
  end

  def onboarding_complete_message(%{organization?: true} = assigns) do
    ~H"""
    <.col class="space-y-4">
      <p>Onboarding is complete.  Your 14 day free trial has begun.</p>
      <p>What would you like to do next?</p>
    </.col>
    """
  end

  def onboarding_complete_message(%{organization?: false} = assigns) do
    ~H"""
    <.col class="space-y-4">
      <p>Onboarding is complete.</p>
      <p>What would you like to do next?</p>
    </.col>
    """
  end

  def step_list(assigns) do
    ~H"""
    <div class="flex flex-col space-y-4">
      <.install_github_app state={@state} step={1} />
      <.sync_data state={@state} step={2} />
      <.review_pr_notifications state={@state} step={3} />
      <.get_to_it state={@state} step={4} />
    </div>
    """
  end

  attr :status, :atom, required: true

  slot :number, required: true
  slot :title, required: true
  slot :description
  slot :inner_block, required: true

  def step_option(assigns) do
    ~H"""
    <div class={"flex items-top space-x-2 p-2 #{border_class(@status)} rounded-md"}>
      <span class={progress_class(@status)}><%= render_slot(@number) %>.</span>
      <div class="flex flex-col flex-1">
        <span class={progress_class(@status)}>
          <%= render_slot(@title) %>
        </span>

        <p :if={!completed?(@status)} class="">
          <%= render_slot(@description) %>
        </p>

        <div class="pt-2">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  def progress_status(%{step: %{number: number}}, component) do
    case component do
      c when c > number -> :todo
      c when c == number -> :in_progress
      c when c < number -> :done
    end
  end

  def set_status(assigns) do
    status = progress_status(assigns.state, assigns.step)

    assign(assigns, :status, status)
  end

  def progress_class(:todo), do: "text-gray-500"
  def progress_class(:in_progress), do: "font-bold"
  def progress_class(:done), do: "line-through text-gray-500"

  def border_class(:todo), do: "border"
  def border_class(:in_progress), do: "border-2 border-teal-700 shadow-lg"
  def border_class(:done), do: "border"

  def completed?(:done), do: true
  def completed?(_), do: false

  def render_stats(%{stats: stats} = assigns) when stats == %{}, do: ~H[]

  def render_stats(assigns) do
    ~H"""
    <p>We've synced your data!  Here are the stats:</p>

    <div class="flex space-x-2">
      <div class="flex flex-col">
        <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />
        <.repository_icon />
        <.icon name="share" class="text-gray-400 mr-1 h-5 w-5" />
      </div>
      <div class="flex flex-col">
        <p>Members</p>
        <p>Repositories</p>
        <p>Pull Requests</p>
      </div>
      <div class="flex flex-col">
        <p class="font-semibold"><%= @stats.members %></p>
        <p class="font-semibold"><%= @stats.repositories %></p>
        <p class="font-semibold"><%= @stats.pull_requests %></p>
      </div>
    </div>
    """
  end

  def install_action(%{installation: nil} = assigns) do
    ~H"""
    <a href={Mrgr.Installation.installation_url()} class="btn btn-primary">
      Click here to install our Github App 🚀
    </a>
    """
  end

  def install_action(assigns) do
    ~H"""
    <p>
      Good News!  Mrgr has been installed to the
      <span class="font-bold"><%= @installation.account.login %></span>
      <%= account_type(@installation) %>.
    </p>
    """
  end

  def syncing_message(%{installation: %{state: state}} = assigns)
      when state in [
             "onboarding_members",
             "onboarding_teams",
             "onboarding_repos",
             "onboarding_prs"
           ] do
    assigns = assign(assigns, :syncing, sync_text(state))

    ~H"""
    <div class="flex flex-col">
      <.col class="space-y-4">
        <.row>
          <p class="font-bold">Syncing in Progress.</p>
          <p>This can take up to a minute.</p>
        </.row>
        <.row class="items-center space-x-4">
          <p>Loading your <%= @syncing %></p>
          <.spinner id="syncing-spinner" />
        </.row>
      </.col>
    </div>
    """
  end

  def syncing_message(%{installation: %{state: "onboarding_error"}} = assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="flex items-center space-x-2">
        <p>We've synced your data!</p>
      </div>
    </div>
    """
  end

  def syncing_message(assigns), do: ~H[]

  defp account_type(installation) do
    case organization?(installation) do
      true -> "organization"
      false -> "user account"
    end
  end

  defp organization?(installation) do
    Mrgr.Schema.Installation.organization?(installation)
  end

  defp sync_text("onboarding_members"), do: "team members"
  defp sync_text("onboarding_teams"), do: "team members"
  defp sync_text("onboarding_repos"), do: "repositories"
  defp sync_text("onboarding_prs"), do: "pull requests"
end
