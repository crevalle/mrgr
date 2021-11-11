defmodule MrgrWeb.LayoutView do
  use MrgrWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def current_account(%{current_installation: %{account: %{login: login}}}), do: " - #{login}"
  def current_account(_), do: ""
end
