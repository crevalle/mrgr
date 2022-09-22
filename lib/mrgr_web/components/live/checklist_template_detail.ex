defmodule MrgrWeb.Components.Live.ChecklistTemplateDetail do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="basis-1/2 p-4 bg-white overflow-hidden shadow rounded-lg">
      <div class="flex flex-col space-y-4">
        <div class="flex justify-between">
          <div class="flex items-start items-center">
            <.h1>Details</.h1>
          </div>
          <button phx-click="close-detail" colors="outline-none">
            <.icon name="x" class="text-gray-400 mr-1 h-5 w-5" />
          </button>
        </div>

        <h3><%= @template.title %></h3>
        Created by <%= @template.creator.nickname %>



      </div>

    </div>
    """
  end
end
