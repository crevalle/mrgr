defmodule Mrgr.Notification.Event do
  defmacro __using__(_opts) do
    quote do
      @pr_controversy "pr_controversy"
      @dormant_pr "dormant_pr"

      @notification_events [
        @pr_controversy,
        @dormant_pr
      ]
    end
  end

  def custom_type(%Mrgr.Schema.PRTab{title: title}) do
    "custom - #{title}"
  end
end
