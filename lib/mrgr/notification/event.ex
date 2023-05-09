defmodule Mrgr.Notification.Event do
  @moduledoc """
  These are defined as macros so I can use them in case-statement pattern matching.
  """

  defmacro pr_controversy do
    quote do: "pr_controversy"
  end

  defmacro pr_dormant do
    quote do: "pr_dormant"
  end


  defmacro all_notification_events do
    quote do
      [
        pr_controversy(),
        pr_dormant()
      ]
    end
  end

end
