defmodule Mrgr.Factory do
  alias Mrgr.Repo

  # Factories

  def build(:desmond) do
    %Mrgr.Schema.User{
      first_name: "Desmond",
      last_name: "Bowe",
      name: "Desmond Bowe",
      email: "desmond@crevalle.io",
      nickname: "desmondmonster",
      refresh_token: Ecto.UUID.generate(),
      token: Ecto.UUID.generate(),
      token_expires_at:
        DateTime.utc_now() |> DateTime.add(14, :day) |> DateTime.truncate(:second),
      token_updated_at:
        DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second),
      urls: %{}
    }
  end

  def build(:user) do
    %Mrgr.Schema.User{
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      name: Faker.StarWars.character(),
      email: Faker.Internet.email(),
      nickname: Faker.Internet.user_name(),
      refresh_token: Ecto.UUID.generate(),
      token: Ecto.UUID.generate(),
      token_expires_at:
        DateTime.utc_now() |> DateTime.add(14, :day) |> DateTime.truncate(:second),
      token_updated_at: DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
    }
  end

  def build(:account) do
    %Mrgr.Schema.Account{
      login: Faker.Superhero.name()
    }
  end

  def build(:installation) do
    %Mrgr.Schema.Installation{
      app_slug: "Socks",
      account: build(:account)
    }
  end

  def build(:membership) do
    %Mrgr.Schema.Membership{
      member: build(:member),
      installation: build(:installation)
    }
  end

  def build(:member) do
    %Mrgr.Schema.Member{
      user: build(:user)
    }
  end

  def build(:repository) do
    installation = build(:installation)
    name = Faker.Company.bullshit()
    full_name = "#{installation.account.login}/#{name}"

    %Mrgr.Schema.Repository{
      name: name,
      full_name: full_name,
      node_id: Ecto.UUID.generate(),
      private: true,
      language: "Elixir",
      installation: installation,
      settings: build(:repository_settings)
    }
  end

  def build(:pull_request) do
    %Mrgr.Schema.PullRequest{
      title: Faker.Company.bs(),
      number: System.unique_integer([:positive, :monotonic]),
      node_id: Ecto.UUID.generate(),
      opened_at: Mrgr.DateTime.safe_truncate(Mrgr.DateTime.now()),
      ci_status: "success",
      status: "open",
      head: build(:head),
      repository: build(:repository)
    }
  end

  def build(:pr_review) do
    %Mrgr.Schema.PRReview{
      pull_request: build(:pull_request),
      user: build(:github_user),
      state: "approved",
      commit_id: Ecto.UUID.generate(),
      node_id: Ecto.UUID.generate(),
      data: %{}
    }
  end

  def build(:comment) do
    posted_at =
      Mrgr.DateTime.safe_truncate(
        DateTime.add(Mrgr.DateTime.now(), 1 - :rand.uniform(386_000), :second)
      )

    %Mrgr.Schema.Comment{
      object: :issue_comment,
      posted_at: posted_at,
      pull_request: build(:pull_request)
    }
  end

  def build(:head) do
    %Mrgr.Schema.Head{
      external_id: 123,
      ref: "Where are the ants?",
      # not really a sha, should be fine :)
      sha: Faker.UUID.v4()
    }
  end

  def build(:high_impact_file) do
    %Mrgr.Schema.HighImpactFileRule{
      repository: build(:repository),
      name: "socks",
      notify_user: false,
      pattern: "*",
      source: :user
    }
  end

  def build(:check) do
    %Mrgr.Schema.Check{
      text: Faker.Company.bs(),
      checklist: build(:checklist)
    }
  end

  def build(:checklist) do
    %Mrgr.Schema.Checklist{
      title: Faker.Company.bs(),
      pull_request: build(:pull_request),
      checklist_template: build(:checklist_template)
    }
  end

  def build(:checklist_template) do
    %Mrgr.Schema.ChecklistTemplate{
      title: Faker.Company.bs(),
      installation: build(:installation),
      creator: build(:user)
    }
  end

  def build(:checklist_template_repository) do
    template = build(:checklist_template)
    repository = build(:repository, installation: template.installation)

    %Mrgr.Schema.ChecklistTemplateRepository{
      checklist_template: template,
      repository: repository
    }
  end

  def build(:repository_settings_policy) do
    %Mrgr.Schema.RepositorySettingsPolicy{
      installation: build(:installation),
      name: Faker.Company.bs(),
      default: false,
      enforce_automatically: true,
      settings: build(:repository_settings)
    }
  end

  def build(:repository_settings) do
    %Mrgr.Schema.RepositorySettings{
      merge_commit_allowed: true,
      rebase_merge_allowed: false,
      squash_merge_allowed: true,
      required_approving_review_count: 1
    }
  end

  def build(:commit) do
    %Mrgr.Github.Commit{
      node_id: Ecto.UUID.generate(),
      # whatevs!
      sha: Ecto.UUID.generate(),
      author: build(:github_user),
      committer: build(:github_user),
      additions: 10,
      deletions: 12,
      message: Faker.Company.bs()
    }
  end

  def build(:github_user) do
    %Mrgr.Github.User{
      avatar_url: Faker.Internet.url(),
      events_url: Faker.Internet.url(),
      followers_url: Faker.Internet.url(),
      following_url: Faker.Internet.url(),
      gists_url: Faker.Internet.url(),
      gravatar_id: Faker.Internet.user_name(),
      html_url: Faker.Internet.url(),
      id: :rand.uniform(100_000),
      login: Faker.Internet.user_name(),
      name: Faker.Person.name(),
      node_id: Ecto.UUID.generate(),
      organizations_url: Faker.Internet.url(),
      received_events_url: Faker.Internet.url(),
      repos_url: Faker.Internet.url(),
      site_admin: true,
      starred_url: Faker.Internet.url(),
      subscriptions_url: Faker.Internet.url(),
      type: "User",
      url: Faker.Internet.url()
    }
  end

  def build(:short_user) do
    date =
      DateTime.truncate(DateTime.add(Mrgr.DateTime.now(), 1 - :rand.uniform(386_000)), :second)

    %Mrgr.Github.Commit.ShortUser{
      date: date,
      email: Faker.Internet.email(),
      name: Faker.Person.name()
    }
  end

  # Convenience API

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end

  def insert_list(factory_name, num, attributes) do
    Enum.map(1..num, fn _i -> insert!(factory_name, attributes) end)
  end
end
