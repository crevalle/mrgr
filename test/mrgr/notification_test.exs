defmodule Mrgr.NotificationTest do
  use Mrgr.DataCase
  use Mrgr.Notification.Event

  describe "create_preference/1" do
    test "creates a preference with default settings" do
      installation = insert!(:installation)
      user = insert!(:user, current_installation: installation)

      {:ok, preference} = Mrgr.Notification.create_preference(@big_pr, user.id, installation.id)

      assert preference.email
      refute preference.slack
      assert preference.settings.big_pr_threshold == 1000
    end
  end
end
