defmodule Mrgr.Installation.SubscriptionState do
  # yon states
  @trial "trial"
  @trial_expired_grace "trial_expired_grace"
  @trial_expired "trial_expired"
  @active "active"
  @cancelled "cancelled"
  @personal "personal"

  def states do
    [
      @trial,
      @trial_expired_grace,
      @trial_expired,
      @active,
      @cancelled,
      @personal
    ]
  end

  def initial, do: @trial

  def subscribed?(%{subscription_state: state}) when state in [@active, @personal], do: true
  def subscribed?(_), do: false

  def trial_period?(%{subscription_state: state}) when state in [@trial], do: true
  def trial_period?(_), do: false

  def active!(%{target_type: "User"} = installation) do
    update_state!(installation, @personal)
  end

  def active!(installation) do
    update_state!(installation, @active)
  end

  def update_state!(installation, state) do
    state_change = build_state_change(state)

    attrs = %{
      subscription_state: state,
      subscription_state_changes: [state_change | installation.subscription_state_changes]
    }

    installation
    |> Mrgr.Schema.Installation.subscription_state_changeset(attrs)
    |> Mrgr.Repo.update!()
  end

  defp build_state_change(state) do
    %Mrgr.Schema.Installation.SubscriptionStateChange{
      state: state,
      transitioned_at: Mrgr.DateTime.now()
    }
  end
end
