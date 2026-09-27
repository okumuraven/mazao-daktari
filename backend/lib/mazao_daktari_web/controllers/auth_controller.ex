defmodule MazaoDaktariWeb.AuthController do
  use MazaoDaktariWeb, :controller

  alias MazaoDaktari.Accounts
  alias MazaoDaktari.Accounts.{GoogleAuth, Session}

  @doc """
  POST /api/auth/google — body: {"credential": "<google id token>"}

  Verifies the ID token the frontend got directly from Google Identity
  Services, upserts the user, and returns our own opaque session token for
  the frontend to send back as `Authorization: Bearer <token>`.
  """
  def google(conn, %{"credential" => credential}) do
    with {:ok, claims} <- GoogleAuth.verify(credential),
         {:ok, user} <- Accounts.get_or_create_from_google(claims) do
      json(conn, %{token: Session.sign(user.id), user: user_json(user)})
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Google sign-in failed", reason: inspect(reason)})
    end
  end

  def google(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing \"credential\"."})
  end

  @doc "GET /api/me — the signed-in user, used by the frontend to restore a session on page load."
  def me(conn, _params) do
    json(conn, %{user: user_json(conn.assigns.current_user)})
  end

  defp user_json(user) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      avatar_url: user.avatar_url,
      joined_at: user.inserted_at
    }
  end
end
