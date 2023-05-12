defmodule MrgrWeb.Components.Core do
  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.

  """
  use Phoenix.Component
  import Heroicons.LiveView, only: [icon: 1]
  import Phoenix.HTML.Form
  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :confirm
  slot :cancel

  def modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} class="relative z-50 hidden">
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-zinc-50/90 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="hidden relative rounded-2xl bg-white p-14 shadow-lg shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label="close"
                >
                  <.icon name="x-mark" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-zinc-800">
                    <%= render_slot(@title) %>
                  </h1>
                  <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <%= render_slot(@inner_block) %>
                <div :if={@confirm != [] or @cancel != []} class="ml-6 mb-4 flex items-center gap-5">
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="py-2 px-3"
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 inline-flex items-center",
        "border border-transparent shadow-md rounded-md bg-teal-700 hover:bg-teal-500 py-2 px-4",
        "text-sm font-medium text-white active:text-white/80",
        "focus:outline-none focus:ring-2 focus:ring-offset-2",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an inline button.

  ## Examples

      <.inline_button>Send!</.inline_button>
      <.inline_button phx-click="go" class="ml-2">Send!</.inline_button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def inline_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 inline-flex items-center px-4",
        "border border-transparent shadow-md rounded-r-md",
        "text-sm font-medium text-white",
        "bg-teal-700 hover:bg-teal-600",
        "focus:ring-2 focus:ring-offset-2 focus:ring-teal-500 focus:border-teal-500",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a button with a transparent background.

  ## Examples

      <.outline_button>Send!</.outline_button>
      <.outline_button phx-click="go" class="ml-2">Send!</.outline_button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def outline_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 inline-flex items-center",
        "border border-transparent shadow-md rounded-md bg-transparent py-2 px-4",
        "text-sm font-medium active:text-black/80",
        "focus:outline-none focus:ring-2 focus:ring-offset-2",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form :let={f} for={:user} phx-change="validate" phx-submit="save">
        <.input field={{f, :email}} label="Email"/>
        <.input field={{f, :username}} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, default: nil, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-8 bg-white mt-10">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  attr :f, :any, required: true
  attr :attr, :any, required: true
  attr :class, :string, default: nil

  def checkbox(assigns) do
    ~H"""
    <%= checkbox(@f, @attr,
      class: [
        "shadow-inner focus:ring-emerald-500 focus:border-emerald-500 border-gray-300 rounded-md",
        @class
      ]
    ) %>
    """
  end

  slot :text, required: true
  slot :inner_block, required: true
  attr :class, :string, default: nil

  attr :rest, :global

  def tooltip(assigns) do
    ~H"""
    <div class={["tooltip", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
      <span class="tooltiptext"><%= render_slot(@text) %></span>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def table(assigns) do
    ~H"""
    <table
      class={[
        "min-w-full shadow ring-1 ring-black ring-opacity-5 rounded-lg",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </table>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def th(assigns) do
    ~H"""
    <th
      scope="col"
      class={[
        "p-3 text-left text-xs bg-gray-100 font-medium uppercase tracking-wide text-gray-500",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </th>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def th_left(assigns) do
    ~H"""
    <th
      scope="col"
      class={[
        "p-3 text-left text-xs font-medium uppercase text-gray-500",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </th>
    """
  end

  attr :class, :string, default: ""
  attr :striped, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def tr(assigns) do
    striped = if assigns.striped, do: "even:bg-white odd:bg-gray-50", else: nil

    class = "#{assigns.class} #{striped}"

    assigns = assign(assigns, :class, class)

    ~H"""
    <tr
      class={[
        "border-t border-gray-300 py-2",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </tr>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def td(assigns) do
    ~H"""
    <td
      class={[
        "whitespace-nowrap px-3 py-2 text-gray-700",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </td>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def ul(assigns) do
    ~H"""
    <ul
      class={[
        "list-disc",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </ul>
    """
  end

  slot :icon, required: true
  slot :inner_block, required: true

  def icon_li(assigns) do
    ~H"""
    <li class="flex items-center space-x-3">
      <%= render_slot(@icon) %>
      <span><%= render_slot(@inner_block) %></span>
    </li>
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def i(assigns) do
    ~H"""
    <.icon
      name={@name}
      class={[
        "h-5 w-5 ",
        @class
      ]}
      {@rest}
    />
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def button_group(assigns) do
    ~H"""
    <div
      class={[
        "flex space-x-4 items-start",
        @class
      ]}
      {@rest }
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def col(assigns) do
    ~H"""
    <div
      class={[
        "flex flex-col",
        @class
      ]}
      {@rest }
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def row(assigns) do
    ~H"""
    <div
      class={[
        "flex items-center",
        @class
      ]}
      {@rest }
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.pop_focus()
  end
end
