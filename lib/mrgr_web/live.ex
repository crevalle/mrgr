defmodule MrgrWeb.Live do

  @moduledoc """
  Site-wide LiveView conveniences
  """

  def put_title(socket, title) do
    prefix = if Mrgr.dev?, do: "Mrgr[dev]", else: "Mrgr"
    Phoenix.Component.assign(socket, page_title: "#{prefix} - #{title}")
  end
end
