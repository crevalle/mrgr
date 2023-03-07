defmodule Mrgr.Schema.Installation do
  use Mrgr.Schema

  schema "installations" do
    field(:access_tokens_url, :string)
    field(:app_id, :integer)
    field(:app_slug, :string)
    field(:data, :map)
    field(:events, {:array, :string})
    field(:external_id, :integer)
    field(:html_url, :string)
    field(:installation_created_at, :utc_datetime)
    field(:onboarding_error, :string)
    field(:permissions, :map)
    field(:repositories_url, :string)
    field(:repository_selection, :string)
    field(:repos_last_synced_at, :utc_datetime)
    field(:state, :string)
    field(:subscription_state, :string)
    field(:target_id, :integer)
    field(:target_type, :string)
    field(:token, :string)
    field(:token_expires_at, :utc_datetime)

    embeds_many :subscription_state_changes, SubscriptionStateChange, on_replace: :delete do
      field(:state, :string)
      field(:transitioned_at, :utc_datetime)
    end

    embeds_many :state_changes, StateChange, on_replace: :delete do
      field(:state, :string)
      field(:transitioned_at, :utc_datetime)
    end

    belongs_to(:creator, Mrgr.Schema.User)
    has_one(:account, Mrgr.Schema.Account)
    has_one(:subscription, Mrgr.Schema.StripeSubscription)

    has_many(:repository_settings_policies, Mrgr.Schema.RepositorySettingsPolicy)

    has_many(:repositories, Mrgr.Schema.Repository)

    has_many(:incoming_webhooks, Mrgr.Schema.IncomingWebhook)

    has_many(:memberships, Mrgr.Schema.Membership)
    has_many(:members, through: [:memberships, :member])
    has_many(:users, through: [:members, :user])

    timestamps()
  end

  @create_params ~w[
    access_tokens_url
    app_id
    app_slug
    creator_id
    events
    external_id
    html_url
    installation_created_at
    data
    permissions
    repositories_url
    repository_selection
    state
    subscription_state
    target_id
    target_type
  ]a

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @create_params)
    |> cast_assoc(:account)
    |> cast_assoc(:repositories)
    |> foreign_key_constraint(:creator_id)
    |> put_external_id()
    |> put_data_map()
    |> validate_inclusion(:state, Mrgr.Installation.State.states())
    |> validate_inclusion(:subscription_state, Mrgr.Installation.SubscriptionState.states())
  end

  @tokens ~w[
    token
    token_expires_at
  ]a

  def tokens_changeset(schema, params) do
    schema
    |> cast(params, @tokens)
    |> validate_required(@tokens)
  end

  def repositories_changeset(schema, params) do
    schema
    |> Mrgr.Repo.preload(:repositories)
    |> cast(params, [])
    |> cast_assoc(:repositories)
  end

  def state_changeset(schema, params) do
    schema
    |> cast(params, [:state, :onboarding_error])
    |> put_embed(:state_changes, params.state_changes)
    |> validate_inclusion(:state, Mrgr.Installation.State.states())
  end

  def subscription_state_changeset(schema, params) do
    schema
    |> cast(params, [:subscription_state])
    |> put_embed(:subscription_state_changes, params.subscription_state_changes)
    |> validate_inclusion(:subscription_state, Mrgr.Installation.SubscriptionState.states())
  end

end
