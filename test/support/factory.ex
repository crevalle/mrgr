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

  def build(:repository) do
    %Mrgr.Schema.Repository{
      name: Faker.Company.bullshit(),
      installation: build(:installation)
    }
  end

  def build(:merge) do
    %Mrgr.Schema.Merge{
      title: Faker.Company.bs(),
      number: System.unique_integer([:positive, :monotonic]),
      status: "open",
      head: build(:head),
      repository: build(:repository)
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

  # Convenience API

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end
end
