defmodule MrgrWeb.Components.Onboarding do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI

  attr :name, :string
  attr :installation, :map
  attr :number, :integer
  attr :stats, :map, default: %{}

  slot :inner_block, default: nil

  def install_github_app(assigns) do
    class =
      case assigns.installation do
        nil -> in_progress()
        _ -> done()
      end

    assigns =
      assigns
      |> assign(:class, class)

    ~H"""
    <.step_option class={@class}>
      <:number>1</:number>
      <:title>
        Install our Github App
      </:title>

      <:description>
        This is how we pull in your pull request data and stay up to date.  Requires admin privileges on your organization.
      </:description>

      <.install_action installation={@installation} />
    </.step_option>
    """
  end

  def sync_data(assigns) do
    class =
      case assigns.installation do
        nil ->
          todo()

        i ->
          case i.state do
            "created" -> todo()
            "onboarding_complete" -> done()
            _the_midst_of_onboarding -> in_progress()
          end
      end

    assigns =
      assigns
      |> assign(:class, class)

    ~H"""
    <.step_option class={@class}>
      <:number>2</:number>
      <:title>
        Sync your data
      </:title>

      <:description>
        We'll do this for you once the app is installed :)
      </:description>

      <.syncing_message installation={@installation} />
      <.render_stats stats={@stats} />
    </.step_option>
    """
  end

  def connect_slack_status(%{done: true}), do: :done
  def connect_slack_status(%{installation: nil}), do: :todo
  def connect_slack_status(%{installation: %{state: "onboarding_complete"}}), do: :in_progress
  def connect_slack_status(_assigns), do: :todo

  def connect_slack(assigns) do
    status = connect_slack_status(assigns)

    assigns =
      assigns
      |> assign(:status, status)
      |> assign(:class, class(status))

    ~H"""
    <.step_option class={@class}>
      <:number>3</:number>
      <:title>
        Connect Slack (optional)
      </:title>

      <:description>
        Want to receive alerts in Slack?  Install our Slackbot!
      </:description>

      <%= if @status != :todo do %>
        <%= if @done do %>
          <.slack_connection_status connected={Mrgr.Installation.slack_connected?(@installation)} />
        <% else %>
          <div class="flex flex-col space-y-4">
            <.slack_button user_id={@user.id} />
            <.l phx-click="skip-slack-install" class="text-sm">Skip for now</.l>
          </div>
        <% end %>
      <% end %>
    </.step_option>
    """
  end

  def step_list(assigns) do
    ~H"""
    <div class="flex flex-col space-y-4">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def step_option(assigns) do
    ~H"""
    <div class="flex items-top space-x-2 p-2 border rounded-md">
      <span class={@class}><%= render_slot(@number) %>.</span>
      <div class="flex flex-col">
        <span class={@class}><%= render_slot(@title) %></span>
        <p class="text-gray-500"><%= render_slot(@description) %></p>

        <div class="pt-2">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  def class(:todo), do: todo()
  def class(:in_progress), do: in_progress()
  def class(:done), do: done()

  def done, do: "line-through text-gray-500"
  def in_progress, do: "font-bold"
  def todo, do: ""

  def get_to_it(assigns) do
    ~H"""
    <div class="flex flex-col space-y-4">
      <p>
        <span class="font-semibold">Hot Dog</span> you are all set!
      </p>
      <a href={~p"/pull-requests"} class="btn btn-primary">
        Let's get Mergin'
      </a>
    </div>
    """
  end

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
    [_, syncing] = String.split(state, "_")

    assigns = assign(assigns, :syncing, syncing)

    ~H"""
    <div class="flex flex-col">
      <div class="flex items-center space-x-2">
        <p class="font-bold">Syncing in Progress.</p>
        <p>This can take up to a minute.</p>
        <p>Syncing your <%= @syncing %></p>
        <.spinner id="syncing-spinner" />
      </div>
    </div>
    """
  end

  def syncing_message(%{installation: %{state: "onboarding_error"}} = assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="flex items-center space-x-2">
        <p class="font-bold">Uh Oh!</p>
        <p>We ran into an issue syncing your data.  Our Customer Support team will be in touch!</p>
      </div>
    </div>
    """
  end

  def syncing_message(assigns), do: ~H[]

  defp account_type(%{target_type: "User"}), do: "user account"
  defp account_type(_org_or_app), do: "organization"
end
