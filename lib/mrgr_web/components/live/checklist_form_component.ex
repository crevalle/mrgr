defmodule MrgrWeb.Components.Live.ChecklistFormComponent do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="basis-1/2 p-4 bg-white overflow-hidden shadow rounded-lg">
      <div class="flex flex-col space-y-4">
        <div class="flex justify-between">
          <div class="flex items-start items-center">
            <.h1>Create a Merge Checklist</.h1>
          </div>
          <button phx-click="close-detail" colors="outline-none">
            <.icon name="x-circle" class="text-gray-400 mr-1 h-5 w-5" />
          </button>
        </div>

        <.form let={f} for={@changeset} phx-change="validate" phx-submit="save" class="flex flex-col space-y-4">
          <div class="flex flex-col mt-1">
            <.input f={f} field={:title} type="text" placeholder="ex. 'Security Checklist'" />
          </div>

          <div class="flex flex-col mt-1">
            <.subheading title="Checks">
              <:description>
                Add a Check for each item in the checklist that must be checked off.
              </:description>
            </.subheading>

            <%= for ct <- inputs_for(f, :check_templates) do %>
              <%= hidden_inputs_for ct %>
              <%= hidden_input ct, :temp_id %>

              <.input f={ct} field={:text} type="text" placeholder="ex. 'There is no SQL Injection'" >
                <:secondary>
                  <%= link "Remove", to: "#", phx_click: "remove-check-template", phx_value_remove: ct.data.temp_id, class: "text-rose-600 hover:text-rose-500  ml-2" %>
                </:secondary>
              </.input>
            <% end %>
          </div>
          <div class="flex items-center mt-1">
            <.icon name="plus-circle" class="text-teal-700 hover:text-teal-500 mr-1 flex-shrink-0 h-6 w-6" />
            <a href="#" phx-click="add-check-template" class="text-teal-700 hover:text-teal-500">Add Another Check</a>
          </div>

          <div class="flex flex-col my-1">
            <.subheading title="Apply to Repositories">
              <:description>
                <div class="flex flex-col">
                  This checklist will apply to ALL merges in the repos you select.
                  <%= link "Toggle All/None", to: "#", phx_click: "toggle-all-repositories", class: "text-teal-700 hover:text-teal-500" %>
                </div>
              </:description>
            </.subheading>

            <div class="my-4">
              <div class="grid grid-cols-3 gap-2">
                <%= for repo <- @repository_list do %>
                  <.toggle_block repo={repo} selected={selected?(repo.id, @selected_repository_ids)} />
                <% end %>
              </div>
            </div>

          </div>
          <div class="flex items-end">
            <.button submit={true} phx_disable_with="Saving..." colors="bg-teal-700 hover:bg-teal-600 focus:ring-teal-500">
              Save
            </.button>
          </div>
        </.form>


      </div>

    </div>
    """
  end

  def selected?(id, selected_ids) do
    Enum.member?(selected_ids, id)
  end
end
