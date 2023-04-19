defmodule Mrgr.Notification.Event do
  defmacro __using__(_opts) do
    quote do
      @pr_controversy "pr_controversy"

      @notification_events [
        @pr_controversy
      ]
    end
  end
end
