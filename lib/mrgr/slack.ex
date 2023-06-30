defmodule Mrgr.Slack do
  @moduledoc """
  Wraps the Slack API
  """

  def send_and_log(message, recipient, type, pull_request \\ []) do
    res = send_message(message, recipient)

    Mrgr.Notification.create(recipient.id, res, "slack", type, pull_request)

    res
  end

  def send_message(message, user) do
    # assumes user has opted to receive slack messages
    address = Mrgr.User.find_user_notification_address(user)

    send_message(message, user.current_installation, address)
  end

  @spec(
    send_message(
      map() | String.t(),
      Mrgr.Schema.Installation.t(),
      Mrgr.Schema.UserNotificationAddress.t()
    ) :: {:ok, map()},
    {:error, String.t()}
  )
  def send_message(message, %{slackbot: %{access_token: token}} = installation, %{
        slack_id: slack_id
      })
      when is_bitstring(message) do
    url = "https://slack.com/api/chat.postMessage"

    headers = %{
      "Content-Type" => "application/x-www-form-urlencoded",
      "Authorization" => "Bearer #{token}"
    }

    params = %{
      channel: slack_id,
      text: message
    }

    body = URI.encode_query(params)

    post(url, body, headers)
    |> handle_stale_bot(installation)
  end

  def send_message(message, %{slackbot: %{access_token: token}} = installation, %{
        slack_id: slack_id
      })
      when is_map(message) do
    url = "https://slack.com/api/chat.postMessage"

    headers = %{
      "Content-Type" => "application/json; charset=utf-8",
      "Authorization" => "Bearer #{token}"
    }

    params = %{channel: slack_id}

    body =
      params
      |> Map.merge(message)
      |> Jason.encode!()

    post(url, body, headers)
    |> handle_stale_bot(installation)
  end

  def send_message(_message, _installation, nil) do
    {:error, "No slack connection for user"}
  end

  def send_message(_message, _installation, _user) do
    {:error, "No slackbot installed at installation"}
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

  # cheap way to reduce errors until i build out a slack events receiver
  def handle_stale_bot({:error, "account_inactive"} = res, installation) do
    Mrgr.Installation.remove_slack_integration(installation)

    res
  end

  def handle_stale_bot(res, _installation) do
    res
  end
end
