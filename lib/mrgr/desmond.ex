defmodule Mrgr.Desmond do
  ### !!! emails to me do not get logged.  i just hardcode myself
  # as the recipient so don't have a user to pull an id off of

  def someone_signed_up(params, user) do
    count = Mrgr.Repo.aggregate(Mrgr.Schema.Userl, :count)

    params
    |> Mrgr.Email.hey_desmond_another_user(count, user)
    |> Mrgr.Mailer.deliver()
  end

  def someone_failed_to_sign_up(params, error) do
    params
    |> Mrgr.Email.hey_desmond_a_busted_user(error)
    |> Mrgr.Mailer.deliver()
  end

  def installation_data_sync_failed(installation, stacktrace, step) do
    %{installation_id: installation.id, stacktrace: stacktrace, step: step}
    |> Mrgr.Email.hey_desmond_onboarding_data_sync_failed()
    |> Mrgr.Mailer.deliver()
  end
end
