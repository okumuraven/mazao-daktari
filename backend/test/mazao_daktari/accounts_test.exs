defmodule MazaoDaktari.AccountsTest do
  use MazaoDaktari.DataCase, async: true

  alias MazaoDaktari.Accounts

  @claims %{
    sub: "google-sub-123",
    email: "farmer@example.com",
    name: "Farmer Jane",
    picture: "https://example.com/pic.jpg"
  }

  test "get_or_create_from_google/1 creates a new user on first sign-in" do
    assert {:ok, user} = Accounts.get_or_create_from_google(@claims)
    assert user.google_sub == "google-sub-123"
    assert user.email == "farmer@example.com"
    assert user.name == "Farmer Jane"
  end

  test "get_or_create_from_google/1 finds the existing user on a repeat sign-in, updating stale profile fields" do
    {:ok, first} = Accounts.get_or_create_from_google(@claims)

    updated_claims = %{@claims | name: "Jane the Farmer", picture: "https://example.com/new.jpg"}
    assert {:ok, second} = Accounts.get_or_create_from_google(updated_claims)

    assert second.id == first.id
    assert second.name == "Jane the Farmer"
    assert second.avatar_url == "https://example.com/new.jpg"
  end

  test "get_user/1 returns nil for an unknown id" do
    assert Accounts.get_user(-1) == nil
  end
end
