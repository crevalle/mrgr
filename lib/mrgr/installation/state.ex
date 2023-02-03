defmodule Mrgr.Installation.State do
  # yon states
  @created "created"
  @onboarding_members "onboarding_members"
  @onboarding_teams "onboarding_teams"
  @onboarding_repos "onboarding_repos"
  @onboarding_prs "onboarding_prs"
  @onboarding_error "onboarding_error"
  @onboarding_complete "onboarding_complete"

  def states do
    [
      @created,
      @onboarding_members,
      @onboarding_teams,
      @onboarding_repos,
      @onboarding_prs,
      @onboarding_error,
      @onboarding_complete
    ]
  end

  def onboarded?(%{state: @onboarding_complete}), do: true
  def onboarded?(_), do: false

  def initial, do: @created

  def onboarding_members!(installation) do
    update_state!(installation, @onboarding_members)
  end

  def onboarding_teams!(installation) do
    update_state!(installation, @onboarding_teams)
  end

  def onboarding_repos!(installation) do
    update_state!(installation, @onboarding_repos)
  end

  def onboarding_prs!(installation) do
    update_state!(installation, @onboarding_prs)
  end

  def onboarding_complete!(installation) do
    update_state!(installation, @onboarding_complete)
  end

  def onboarding_error!(installation) do
    update_state!(installation, @onboarding_error)
  end

  def update_state!(installation, state) do
    state_change = build_state_change(state)

    attrs = %{
      state: state,
      state_changes: [state_change | installation.state_changes]
    }

    installation
    |> Mrgr.Schema.Installation.state_changeset(attrs)
    |> Mrgr.Repo.update!()
  end

  defp build_state_change(state) do
    %Mrgr.Schema.Installation.StateChange{
      state: state,
      transitioned_at: Mrgr.DateTime.now()
    }
  end
end
