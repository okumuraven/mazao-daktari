defmodule MazaoDaktari.Accounts.GoogleAuth do
  @moduledoc """
  Verifies a Google Identity Services ID token (a signed JWT the frontend
  gets directly from Google after the user signs in) by delegating
  signature/expiry/issuer checks to Google's own `tokeninfo` endpoint.

  This trades a small amount of latency and a dependency on Google's uptime
  for skipping local JWKS fetching/caching and RS256 verification code
  entirely — a reasonable trade for this app's traffic volume. Per Google's
  own docs this endpoint is intended for debugging/low-volume use; a
  higher-traffic deployment should switch to local verification against
  https://www.googleapis.com/oauth2/v3/certs (e.g. via `Joken`/`JokenJwks`)
  instead of adding load-bearing traffic to `tokeninfo`.
  """

  require Logger

  @tokeninfo_url "https://oauth2.googleapis.com/tokeninfo"
  @valid_issuers ["accounts.google.com", "https://accounts.google.com"]

  @type claims :: %{
          sub: String.t(),
          email: String.t(),
          name: String.t() | nil,
          picture: String.t() | nil
        }

  @spec verify(String.t()) :: {:ok, claims()} | {:error, atom() | String.t()}
  def verify(id_token) when is_binary(id_token) and id_token != "" do
    client_id = Application.get_env(:mazao_daktari, :google_client_id)

    cond do
      client_id in [nil, ""] ->
        Logger.error("GOOGLE_CLIENT_ID is not configured; refusing to verify Google sign-in")
        {:error, :google_client_id_not_configured}

      true ->
        case Req.get(@tokeninfo_url, params: [id_token: id_token], receive_timeout: 10_000) do
          {:ok, %Req.Response{status: 200, body: body}} ->
            validate_claims(body, client_id)

          {:ok, %Req.Response{status: status, body: body}} ->
            {:error, "Google rejected token (#{status}): #{inspect(body)}"}

          {:error, exception} ->
            {:error, "Google tokeninfo request failed: #{Exception.message(exception)}"}
        end
    end
  end

  def verify(_), do: {:error, :missing_token}

  defp validate_claims(
         %{"aud" => aud, "iss" => iss, "sub" => sub, "email" => email} = body,
         client_id
       ) do
    cond do
      aud != client_id ->
        {:error, :audience_mismatch}

      iss not in @valid_issuers ->
        {:error, :invalid_issuer}

      true ->
        {:ok,
         %{
           sub: sub,
           email: email,
           name: Map.get(body, "name"),
           picture: Map.get(body, "picture")
         }}
    end
  end

  defp validate_claims(_body, _client_id), do: {:error, :incomplete_claims}
end
