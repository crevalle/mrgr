defmodule MrgrWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use MrgrWeb, :controller
      use MrgrWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: MrgrWeb

      import Plug.Conn
      import MrgrWeb.Plug.Auth
      import MrgrWeb.Gettext
      alias MrgrWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/mrgr_web/templates",
        namespace: MrgrWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      import MrgrWeb.Plug.Auth

      unquote(components())

      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MrgrWeb.LayoutView, "live.html"}

      import Mrgr.TupleHelpers

      alias Phoenix.LiveView.JS

      on_mount MrgrWeb.Locale

      unquote(components())

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Mrgr.TupleHelpers

      unquote(components())

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
      import MrgrWeb.Plug.Auth
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import MrgrWeb.Gettext
    end
  end

  defp components do
    quote do
      # function component helpers
      import MrgrWeb.Components.UI
      import MrgrWeb.Components.Form
    end
  end

  defp view_helpers do
    quote do
      use Phoenix.HTML
      use PetalComponents

      import Phoenix.LiveView.Helpers

      import Phoenix.View

      import MrgrWeb.Formatter

      import MrgrWeb.ErrorHelpers
      import MrgrWeb.Gettext

      import Heroicons.LiveView, only: [icon: 1]

      import MrgrWeb.Plug.Auth, only: [admin?: 1, signed_in?: 1]

      alias MrgrWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
