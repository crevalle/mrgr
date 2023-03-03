defmodule MrgrWeb.Components.Live.EnforceRepositoryPolicy do
  use MrgrWeb, :live_component

  import MrgrWeb.Components.Repository

  def render(assigns) do
    ~H"""
    <div>
      <.spinner id={"spinner-#{@repo.id}"} class="hidden" />

      <div
        id={"enforce-policy-#{@repo.id}"}
        data-hide={JS.hide()}
        data-show={JS.show(transition: {"ease-out duration-300", "opacity-0", "opacity-100"})}
        class="relative"
      >
        <.l
          phx-click={
            JS.toggle(
              to: "#enforce-policy-menu-#{@repo.id}",
              in:
                {"transition ease-out duration-100", "transform opacity-0 scale-95",
                 "transform opacity-100 scale-100"},
              out:
                {"transition ease-in duration-75", "transform opacity-100 scale-100",
                 "transform opacity-0 scale-95"}
            )
          }
          phx-click-away={
            JS.hide(
              to: "#enforce-policy-menu-#{@repo.id}",
              transition: {"ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
            )
          }
          id={"enforce-policy-menu-button-#{@repo.id}"}
          aria-expanded="false"
          aria-haspopup="true"
          class="flex items-center px-2 py-1 text-gray-700 hover:bg-gray-50 rounded-md font-light text-sm"
        >
          <.repo_policy_name repo={@repo} />
          <.icon name="chevron-down" class="ml-1 h-3 w-3" />
        </.l>

        <div
          style="display: none;"
          id={"enforce-policy-menu-#{@repo.id}"}
          class="origin-top-right z-50 mt-2 w-64 absolute right-0 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none"
          role="menu"
          aria-orientation="vertical"
          aria-labelledby={"enforce-policy-menu-button-#{@repo.id}"}
          tabindex="-1"
        >
          <div class="mt-2 flex flex-col text-sm text-gray-500 sm:mt-0">
            <!-- title -->
            <div class="flex justify-center">
              <p class="px-3 pt-3 text-gray-900">Enforce Policy</p>
            </div>
            <p class="p-3 text-center border-b">
              Select a policy to push its settings to your repository on Github.
            </p>
            <!-- current policy default action -->
            <.enforce_policy_link
              :if={Mrgr.Repository.has_policy?(@repo)}
              policy_id={@repo.policy.id}
              repo_id={@repo.id}
            >
              <div class="flex items-center justify-between">
                <%= @repo.policy.name %>
                <p class="text-gray-500 hover:text-gray-500 font-light italic">
                  current policy
                </p>
              </div>
            </.enforce_policy_link>

            <.enforce_policy_link
              :for={policy <- Mrgr.List.remove(@policies, @repo.policy)}
              policy_id={policy.id}
              repo_id={@repo.id}
            >
              <%= policy.name %>
            </.enforce_policy_link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
