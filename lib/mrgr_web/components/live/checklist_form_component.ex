defmodule MrgrWeb.Components.Live.ChecklistFormComponent do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="basis-1/2 p-4 bg-white overflow-hidden shadow rounded-lg">
      <div class="flex flex-col space-y-4">
        <div class="flex justify-between">
          <div class="flex items-start items-center">
            <.h1>Create a Checklist</.h1>
          </div>
          <button phx-click="close-detail" colors="outline-none">
            <.icon name="x" class="text-gray-400 mr-1 h-5 w-5" />
          </button>
        </div>

        <.form let={f} for={@changeset} phx-change="validate" phx-submit="save" class="flex flex-col space-y-4">
          <div class="flex flex-col mt-1">
            <%= label f, :title %>
            <%= text_input f, :title, [placeholder: "ex. 'Security Checklist'"] %>
            <.error form={f} attr={:title} />
          </div>

          <div class="flex flex-col mt-1">
            Checks
            <%= for ct <- inputs_for(f, :check_templates) do %>
              <%= hidden_inputs_for ct %>
              <%= hidden_input ct, :temp_id %>

              <%= label ct, :text %>
              <div class="flex items-center">
                <%= text_input ct, :text, [placeholder: "ex. 'There is no SQL Injection'", class: "basis-10/12"] %>
                <%= link "Remove", to: "#", phx_click: "remove-check-template", phx_value_remove: ct.data.temp_id, class: "text-red-400 ml-2" %>
              </div>
              <.error form={ct} attr={:text} />
            <% end %>
          </div>
          <div class="flex flex-col mt-1">
            <a href="#" phx-click="add-check-template" class="text-teal-500">Add Another Check</a>
          </div>
          <div class="flex items-end">
            <.button submit={true} phx_disable_with="Saving..." colors="bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-500">
              Save
            </.button>
          </div>
        </.form>


      </div>

    </div>
    """
  end
end
