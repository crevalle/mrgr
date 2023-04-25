defmodule MrgrWeb.SlackController do
  use MrgrWeb, :controller

  require Logger

  def callback(conn, %{"error" => "access_denied", "error_description" => reason}) do
    Logger.warn(reason)

    conn
    |> put_flash(:info, "Slack installation cancelled")
    |> redirect(to: "/profile")
  end

  # bot install
  def callback(conn, %{"code" => code, "state" => user_id}) do
    case exchange_code_for_access_token(code) do
      {:ok, res} ->
        case correct_user?(String.to_integer(user_id), conn.assigns.current_user) do
          true ->
            set_slackbot_info_on_current_installation(conn.assigns.current_user, res)

            conn
            |> put_flash(:info, "Slack added!")
            |> redirect(to: "/profile")

          false ->
            conn
            |> put_flash(:info, "Slack installation failed - user mismatch")
            |> redirect(to: "/profile")
        end

      {:error, reason} ->
        Logger.warn(reason)

        conn
        |> put_flash(:info, "Slack installation failed :(")
        |> redirect(to: "/profile")
    end
  end

  defp correct_user?(id, %{id: id}), do: true
  defp correct_user?(_other_id, _current_user), do: false

  def set_slackbot_info_on_current_installation(
        %{current_installation: installation} = user,
        data
      ) do
    Mrgr.User.set_slack_contact_at_installation(user, installation, data["authed_user"]["id"])

    Mrgr.Installation.set_slackbot_info(installation, data)
  end

  defp exchange_code_for_access_token(code) do
    url = "https://slack.com/api/oauth.v2.access"
    headers = %{"Content-Type" => "application/x-www-form-urlencoded"}

    params = %{
      code: code,
      client_id: Application.get_env(:mrgr, :slack)[:client_id],
      client_secret: Application.get_env(:mrgr, :slack)[:client_secret]
    }

    body = URI.encode_query(params)

    Mrgr.Slack.post(url, body, headers)
  end
end
