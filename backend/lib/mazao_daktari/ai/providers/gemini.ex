defmodule MazaoDaktari.AI.Providers.Gemini do
  @moduledoc """
  Google Gemini multimodal `generateContent` provider.
  """

  @behaviour MazaoDaktari.AI.Provider

  alias MazaoDaktari.AI.Prompt

  @base_url "https://generativelanguage.googleapis.com/v1beta/models"

  def model, do: Application.get_env(:mazao_daktari, :gemini_model, "gemini-2.0-flash")

  @impl true
  def diagnose(api_key, description, image_binary, mime_type, language) do
    parts = [%{text: Prompt.instructions(description, language)}]

    parts =
      if image_binary do
        parts ++
          [
            %{
              inline_data: %{
                mime_type: mime_type || "image/jpeg",
                data: Base.encode64(image_binary)
              }
            }
          ]
      else
        parts
      end

    body = %{contents: [%{parts: parts}]}
    url = "#{@base_url}/#{model()}:generateContent"

    case Req.post(url, json: body, params: [key: api_key], receive_timeout: 30_000) do
      {:ok, %Req.Response{status: 200, body: response_body}} ->
        parse(response_body)

      {:ok, %Req.Response{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %Req.Response{status: status, body: response_body}} ->
        {:error, %{error: "Gemini API error", status: status, detail: response_body}}

      {:error, exception} ->
        {:error, %{error: "Gemini request failed", detail: Exception.message(exception)}}
    end
  end

  defp parse(%{"candidates" => [%{"content" => %{"parts" => parts}} | _]}) do
    text =
      parts
      |> Enum.map_join("", fn part -> Map.get(part, "text", "") end)
      |> Prompt.strip_code_fences()

    case Jason.decode(text) do
      {:ok, parsed} -> {:ok, Map.put(parsed, "mock", false)}
      {:error, _} -> {:error, %{error: "Model returned non-JSON output.", raw: text}}
    end
  end

  defp parse(other), do: {:error, %{error: "Unexpected Gemini response shape", detail: other}}
end
