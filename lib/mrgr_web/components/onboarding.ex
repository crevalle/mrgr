defmodule MrgrWeb.Components.Onboarding do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI

  def step(%{name: "install_github_app"} = assigns) do
    class =
      case assigns.installation do
        nil -> in_progress()
        _ -> done()
      end

    assigns =
      assigns
      |> assign(:class, class)

    ~H"""
    <.step_option class={@class} name={@name}>
      <:number><%= @number %></:number>
      <:title>
        Install our Github App
      </:title>

      <:description>
        This is how we pull in your pull request data and stay up to date.  Requires admin privileges on your organization.
      </:description>
    </.step_option>
    """
  end

  def step(%{name: "sync_data"} = assigns) do
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
    <.step_option class={@class} name={@name}>
      <:number>2</:number>
      <:title>
        Sync your data
      </:title>

      <:description>
        We'll do this for you once the app is installed :)
      </:description>
    </.step_option>
    """
  end

  def step(%{name: "done"} = assigns) do
    class =
      case assigns.installation do
        nil ->
          todo()

        i ->
          case i.subscription_state do
            "onboarding_complete" -> in_progress()
            _not_yet_pal -> todo()
          end
      end

    assigns =
      assigns
      |> assign(:class, class)

    ~H"""
    <.step_option class={@class} name={@name}>
      <:number><%= @number %></:number>
      <:title>
        Get to work!
      </:title>

      <:description>
        yeehaw 🤠
      </:description>
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
      </div>
    </div>
    """
  end

  def done, do: "line-through text-gray-500"
  def in_progress, do: "font-bold"
  def todo, do: ""

  def action(%{installation: nil} = assigns) do
    ~H"""
    <.l href={Mrgr.Installation.installation_url()} class="btn btn-primary ">
      Click here to install our Github App 🚀
    </.l>
    """
  end

  def action(%{installation: %{state: state}} = assigns)
      when state in ["onboarding_complete"] do
    ~H"""
    <div class="flex flex-col space-y-4">
      <p>
        <span class="font-semibold">Hot Dog</span> you are all set!
      </p>
      <.l href="/pull-requests" class="btn btn-primary">
        Let's get Mergin'
      </.l>
    </div>
    """
  end

  def action(assigns), do: ~H[]

  def render_stats(%{stats: stats} = assigns) when stats == %{}, do: ~H[]

  def render_stats(assigns) do
    ~H"""
    <p>We've synced your data.  Here are the stats:</p>

    <table class="w-1/3">
      <tr>
        <td>
          <div class="flex items-center space-x-1">
            <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />Members
          </div>
        </td>
        <td class="font-semibold"><%= @stats.members %></td>
      </tr>
      <tr>
        <td>
          <div class="flex items-center space-x-1"><.repository_icon />Repositories</div>
        </td>
        <td class="font-semibold"><%= @stats.repositories %></td>
      </tr>
      <tr>
        <td>
          <div class="flex items-center space-x-1">
            <.icon name="share" class="text-gray-400 mr-1 h-5 w-5" />Pull Requests
          </div>
        </td>
        <td class="font-semibold"><%= @stats.pull_requests %></td>
      </tr>
    </table>
    """
  end

  def installed_message(%{installation: nil} = assigns), do: ~H[]

  def installed_message(assigns) do
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

  def payment_or_activate_button(%{installation: %{target_type: "User"}} = assigns) do
    ~H"""
    <.l phx-click="activate" class="btn btn-primary">
      Activate your free Mrgr account!
    </.l>
    """
  end

  def payment_or_activate_button(assigns) do
    ~H"""

    """
  end
end
