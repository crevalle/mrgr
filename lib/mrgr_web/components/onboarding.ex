defmodule MrgrWeb.Components.Onboarding do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI

  def step(%{name: "install_github_app"} = assigns) do
    class =
      case assigns.state do
        "new" -> in_progress()
        _ -> done()
      end

    assigns =
      assigns
      |> assign(:class, class)

    ~H"""
    <.step_option class={@class} name={@name}>
      <:number>1</:number>
      <:title>
        Install our Github App
      </:title>

      <:description>
        This integration loads your Pull Request data and sets up webhooks so we have the latest data.
      </:description>
    </.step_option>
    """
  end

  def step(%{name: "sync_data"} = assigns) do
    class =
      case assigns.state do
        "new" -> todo()
        "created" -> in_progress()
        _ -> done()
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

  def step(%{name: "create_subscription"} = assigns) do
    class =
      case assigns.state do
        "active" -> done()
        "onboarding_subscription" -> in_progress()
        _ -> todo()
      end

    assigns =
      assigns
      |> assign(:class, class)

    ~H"""
    <.step_option class={@class} name={@name}>
      <:number>3</:number>
      <:title>
        Create your Subscription 💸
      </:title>

      <:description>
        Mrgr is free for personal (ie, non-Organization) accounts
      </:description>
    </.step_option>
    """
  end

  def step(%{name: "done"} = assigns) do
    class =
      case assigns.state do
        "active" -> in_progress()
        _ -> todo()
      end

    assigns =
      assigns
      |> assign(:class, class)

    ~H"""
    <.step_option class={@class} name={@name}>
      <:number>4</:number>
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

  def li(assigns) do
    ~H"""
    <li class={["", @class]}>
      <%= render_slot(@inner_block) %>
    </li>
    """
  end

  def action(%{state: "new"} = assigns) do
    ~H"""
    <.l href={Mrgr.Installation.installation_url()} class="btn">
      Click here to install our Github App 🚀
    </.l>
    """
  end

  def action(%{state: "active"} = assigns) do
    ~H"""
    <div class="flex flex-col space-y-4">
      <p>
        <span class="font-semibold">Hot Dog</span> you are all set!
      </p>
      <.l href="/pull-requests" class="btn">
        Let's get Mergin'
      </.l>
    </div>
    """
  end

  def action(assigns) do
    ~H"""
    <%= live_render(@socket, MrgrWeb.Live.InstallationLoading,
      id: "installation-sync-#{@installation.id}",
      session: %{"installation_id" => @installation.id}
    ) %>
    """
  end
end
