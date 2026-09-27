defmodule MazaoDaktariWeb.Plugs.Auth do
  @moduledoc """
  Reads `Authorization: Bearer <token>`, verifies it via
  `MazaoDaktari.Accounts.Session`, and assigns `:current_user` (or `nil`).

  Two plug functions so routes can opt into whichever they need:
  `fetch_current_user/2` never rejects the request — diagnosis works for
  both anonymous and signed-in callers, saving history only for the latter.
  `require_user/2` 401s if `fetch_current_user/2` didn't find a valid one.
  """

  import Plug.Conn

  alias MazaoDaktari.Accounts
  alias MazaoDaktari.Accounts.Session

  # `plug MazaoDaktariWeb.Plugs.Auth, :fetch_current_user` (a module plug,
  # since it's referenced from another module's pipeline) resolves to
  # `init/1` then `call/2` — dispatch to the named function plug below
  # rather than defining separate single-purpose plug modules.
  def init(opts), do: opts
  def call(conn, :fetch_current_user), do: fetch_current_user(conn, [])
  def call(conn, :require_user), do: require_user(conn, [])

  def fetch_current_user(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user_id} <- Session.verify(token),
         %Accounts.User{} = user <- Accounts.get_user(user_id) do
      assign(conn, :current_user, user)
    else
      _ -> assign(conn, :current_user, nil)
    end
  end

  def require_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> Phoenix.Controller.json(%{error: "Sign in required."})
      |> halt()
    end
  end
end
