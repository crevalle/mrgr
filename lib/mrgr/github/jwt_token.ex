defmodule Mrgr.Github.JwtToken do
  use Joken.Config, default_signer: :rs256

  def signed_jwt do
    current_timestamp = DateTime.utc_now() |> DateTime.to_unix()

    {github_app_id, _remainder} = System.get_env("GITHUB_APP_IDENTIFIER") |> Integer.parse()

    extra_claims = %{
      "iat" => current_timestamp,
      "exp" => current_timestamp + 10 * 60,
      "iss" => github_app_id
    }

    generate_and_sign!(extra_claims)
  end
end
