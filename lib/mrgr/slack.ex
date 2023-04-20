defmodule Mrgr.Slack do
  @moduledoc """
  Wraps the Slack API
  """

  def send_message(message, user) do
    # assumes user has opted to receive slack messages
    address = Mrgr.User.find_user_notification_address(user)

    send_message(message, user.current_installation, address)
  end

  @spec(
    send_message(
      map(),
      Mrgr.Schema.Installation.t(),
      Mrgr.Schema.UserNotificationAddress.t()
    ) :: {:ok, map()},
    {:error, String.t()}
  )
  def send_message(message, %{slackbot: %{access_token: token}}, %{slack_id: slack_id})
      when is_map(message) do
    url = "https://slack.com/api/chat.postMessage"

    headers = %{
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{token}"
    }

    params = %{channel: slack_id}

    body =
      params
      |> Map.merge(message)
      |> Jason.encode!()

    post(url, body, headers)
  end

  def send_message(_message, _installation, nil) do
    {:error, "No slack connection for user"}
  end

  def post(url, body, headers) do
    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"ok" => true} = res ->
            {:ok, res}

          %{"ok" => false, "error" => reason} ->
            {:error, reason}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
