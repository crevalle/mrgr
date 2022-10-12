defmodule MrgrWeb.Components.Live.ChecklistTemplateDetail do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="basis-1/2 p-4 bg-white overflow-hidden shadow rounded-lg">
      <div class="flex flex-col space-y-4">
        <div class="flex justify-between">
          <div class="flex items-start items-center">
            <.h1><%= @template.title %></.h1>
          </div>
          <button phx-click="close-detail" colors="outline-none">
            <.icon name="x-circle" class="text-teal-700 hover:text-teal-500 mr-1 h-5 w-5" />
          </button>
        </div>

        <div class="flex flex-col">
          <p>Created by <%= @template.creator.nickname %></p>
          <p class="text-gray-500">Updated <%= ts(@template.inserted_at, @timezone) %></p>
        </div>

        <.h3>Check Templates</.h3>
        <ul>

          <%= for ct <- @template.check_templates do %>
            <li><%= ct.text %></li>
          <% end %>
        </ul>

        <.h3>Applies to Repos</.h3>
        <ul>
        <%= for repo <- @template.repositories do %>
          <li><%= repo.name %></li>
        <% end %>
        </ul>


        <%= link "Delete", to: "#", data: [confirm: "Sure about that?"], phx_click: "delete", phx_value_id: @template.id, class: "btn ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-rose-600 hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500" %>
      </div>

    </div>
    """
  end
end
