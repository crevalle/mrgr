defmodule Mrgr.Slack do
  @moduledoc """
  Wraps the Slack API
  """

  @spec(
    send_message(
      String.t(),
      Mrgr.Schema.Installation.t(),
      Mrgr.Schema.UserNotificationAddress.t()
    ) :: {:ok, map()},
    {:error, String.t()}
  )
  def send_message(message, %{slackbot: %{access_token: token}}, %{slack_id: slack_id}) do
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
