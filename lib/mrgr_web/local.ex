defmodule MrgrWeb.Locale do
  def mount(params, session, socket) do
    IO.inspect(params, label: "params")
    IO.inspect(session, label: "session")
    {:cont, socket}
  end
end
