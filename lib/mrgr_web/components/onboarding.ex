defmodule MrgrWeb.Components.Onboarding do
  use MrgrWeb, :component

  # import MrgrWeb.JS
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
    <.li class={@class}>
      Install our Github App.  This lets us load your Pull Request data and receive webhooks with new info!
    </.li>
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
    <.li class={@class}>
      Sync your data (we do this for you :)
    </.li>
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

  def action(assigns) do
    ~H"""
    <%= live_render(@socket, MrgrWeb.Live.InstallationLoading,
      id: "installation-sync-#{@installation.id}",
      session: %{"installation_id" => @installation.id}
    ) %>
    """
  end
end
