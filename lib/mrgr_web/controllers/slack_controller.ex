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
  # %{"code" => "5123613851587.5121644340789.2c7d950052e7ea2947c1493ab16984e70bf1babcac953b4eecf3311cbda5d660", "state" => ""}
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

  def set_slackbot_info_on_current_installation(%{current_installation: installation}, data) do
    Mrgr.Installation.set_slackbot_info(installation, data)
  end

  def results do
    %{
      "access_token" => "xoxb-5123613851587-5127199667092-yDPmmMprXibFfkveEZ4U8X5E",
      "app_id" => "A054BD0BDJL",
      "authed_user" => %{"id" => "U05375TMDEK"},
      "bot_user_id" => "U053R5VKM2Q",
      "enterprise" => nil,
      "is_enterprise_install" => false,
      "ok" => true,
      "scope" => "chat:write,im:write",
      "team" => %{"id" => "T053MJ1R1H9", "name" => "Mrgr"},
      "token_type" => "bot"
    }
  end

  # def signed_in_destination(conn, _user, :new) do
  # conn
  # |> put_flash(:info, "Welcome to Mrgr! 👋")
  # |> redirect(to: ~p"/onboarding")
  # end

  # def signed_in_destination(conn, _user, :returning) do
  # conn
  # |> put_flash(:info, "Welcome Back! 👋")
  # |> redirect(to: ~p"/pull-requests")
  # end

  # def signed_in_destination(conn, user, :invited) do
  # conn
  # |> put_flash(
  # :info,
  # "Welcome to Mrgr!  We've automatically added you to the #{MrgrWeb.Formatter.account_name(user)} account! 👋"
  # )
  # |> redirect(to: ~p"/pull-requests")
  # end

  defp exchange_code_for_access_token(code) do
    # curl -F code=1234 -F client_id=3336676.569200954261 -F client_secret=ABCDEFGH
    url = "https://slack.com/api/oauth.v2.access"
    headers = %{"Content-Type" => "application/x-www-form-urlencoded"}

    params = %{
      code: code,
      client_id: Application.get_env(:mrgr, :slack)[:client_id],
      client_secret: Application.get_env(:mrgr, :slack)[:client_secret]
    }

    body = URI.encode_query(params)

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
