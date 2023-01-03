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

  def static_paths,
    do:
      ~w(assets fonts images favicon.ico manifest.json apple-touch-icon.png android-chrome-192x192.png android-chrome-512x512.png favicon-16x16.png favicon-132x32.png robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: MrgrWeb

      import Plug.Conn
      import MrgrWeb.Plug.Auth
      import MrgrWeb.Gettext
      alias MrgrWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/mrgr_web/templates",
        namespace: MrgrWeb

      use Appsignal.Phoenix.View

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
        layout: {MrgrWeb.LayoutView, :live}

      import Mrgr.Tuple
      import MrgrWeb.Live

      alias Phoenix.LiveView.JS
      alias MrgrWeb.Live.Flash

      on_mount MrgrWeb.Locale

      unquote(components())

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Mrgr.Tuple

      alias Phoenix.LiveView.JS
      alias MrgrWeb.Live.Flash

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
      import MrgrWeb.Components.Core
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Phoenix.Component

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import MrgrWeb.Formatter

      import MrgrWeb.ErrorHelpers
      import MrgrWeb.Gettext

      import Heroicons.LiveView, only: [icon: 1]

      import MrgrWeb.Plug.Auth, only: [admin?: 1, signed_in?: 1]

      alias MrgrWeb.Router.Helpers, as: Routes

      import MrgrWeb.JS

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: MrgrWeb.Endpoint,
        router: MrgrWeb.Router,
        statics: MrgrWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
