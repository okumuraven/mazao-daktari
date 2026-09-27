defmodule MazaoDaktari.Accounts.Session do
  @moduledoc """
  Issues/verifies the opaque session token the frontend holds after Google
  sign-in (sent back as `Authorization: Bearer <token>`). Built on
  `Phoenix.Token` (signed against the endpoint's `secret_key_base`) rather
  than a JWT library — this token is opaque to the frontend and only ever
  round-trips to this same backend, so there's no interoperability need a
  real JWT would buy us.
  """

  @salt "mazao_daktari user auth"
  @max_age_seconds 60 * 60 * 24 * 30

  @spec sign(integer()) :: String.t()
  def sign(user_id) do
    Phoenix.Token.sign(MazaoDaktariWeb.Endpoint, @salt, user_id)
  end

  @spec verify(String.t()) :: {:ok, integer()} | {:error, atom()}
  def verify(token) do
    Phoenix.Token.verify(MazaoDaktariWeb.Endpoint, @salt, token, max_age: @max_age_seconds)
  end
end
