defmodule Mrgr.Factory do
  alias Mrgr.Repo

  # Factories

  def build(:installation) do
    %Mrgr.Schema.Installation{app_slug: "Socks"}
  end

  def build(:repository) do
    %Mrgr.Schema.Repository{name: Faker.Company.bullshit()}
  end

  def build(:merge) do
    %Mrgr.Schema.Merge{
      title: Faker.Company.bs(),
      number: System.unique_integer([:positive, :monotonic]),
      status: "open"
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
