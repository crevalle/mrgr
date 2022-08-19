defmodule Mrgr.Github.WebhookTest do
  use Mrgr.DataCase

  describe "installation created" do
    setup [:with_install_user]

    test "creates an installation" do
      payload = read_webhook_data("installation", "created")

      Mrgr.Github.Webhook.handle("installation", payload)

      assert Mrgr.Repo.get_by(Mrgr.Schema.Installation, external_id: 20_310_985)
    end
  end

  # describe "pull_request opened" do
  # test "creates a new PR" do
  # payload = read_webhook_data("pull_request", "opened")

  # Mrgr.Merge.handle("pull_request", payload)
  # end
  # end

  # a user signs up, then authorizes the app
  defp with_install_user(_ctx) do
    installer = insert!(:desmond)

    %{installer: installer}
  end

  defp read_webhook_data(obj, action) do
    path = Path.join([File.cwd!(), "test", "webhook", obj, "#{action}.json"])

    path
    |> File.read!()
    |> Jason.decode!()
  end
end
