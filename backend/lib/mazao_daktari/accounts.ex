defmodule MazaoDaktari.Accounts do
  @moduledoc """
  User accounts, sourced entirely from Google Sign-In — there is no
  password/local-account path.
  """

  import Ecto.Query, warn: false

  alias MazaoDaktari.Repo
  alias MazaoDaktari.Accounts.{User, GoogleAuth}

  @doc "Finds a user by id."
  @spec get_user(integer()) :: User.t() | nil
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Finds the user for a Google `sub` (stable per-account Google identifier),
  creating one on first sign-in. Updates name/avatar on every sign-in so a
  changed Google profile picture/name stays in sync.
  """
  @spec get_or_create_from_google(GoogleAuth.claims()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_from_google(%{sub: sub, email: email, name: name, picture: picture}) do
    attrs = %{google_sub: sub, email: email, name: name, avatar_url: picture}

    case Repo.get_by(User, google_sub: sub) do
      nil -> %User{} |> User.changeset(attrs) |> Repo.insert()
      user -> user |> User.changeset(attrs) |> Repo.update()
    end
  end
end
