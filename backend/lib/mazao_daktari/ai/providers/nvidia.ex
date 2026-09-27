defmodule MazaoDaktari.AI.Providers.Nvidia do
  @moduledoc """
  NVIDIA Build (`integrate.api.nvidia.com`) provider, used as a rotation
  fallback alongside the Gemini keys. Uses the OpenAI-compatible chat
  completions endpoint with a vision-capable hosted model, so it can take
  the same photo + description input the Gemini provider does.

  The exact model on NVIDIA's catalog moves over time; override via the
  `NVIDIA_MODEL` env var if the default here has been retired.
  """

  @behaviour MazaoDaktari.AI.Provider

  alias MazaoDaktari.AI.Prompt

  @url "https://integrate.api.nvidia.com/v1/chat/completions"

  def model,
    do: Application.get_env(:mazao_daktari, :nvidia_model, "meta/llama-3.2-11b-vision-instruct")

  @impl true
  def diagnose(api_key, description, image_binary, mime_type, language) do
    text = Prompt.instructions(description, language)

    content =
      if image_binary do
        data_url = "data:#{mime_type || "image/jpeg"};base64,#{Base.encode64(image_binary)}"

        [
          %{type: "text", text: text},
          %{type: "image_url", image_url: %{url: data_url}}
        ]
      else
        text
      end

    body = %{
      model: model(),
      messages: [%{role: "user", content: content}],
      max_tokens: 1024,
      temperature: 0.2
    }

    headers = [{"authorization", "Bearer #{api_key}"}]

    case Req.post(@url, json: body, headers: headers, receive_timeout: 30_000) do
      {:ok, %Req.Response{status: 200, body: response_body}} ->
        parse(response_body)

      {:ok, %Req.Response{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %Req.Response{status: status, body: response_body}} ->
        {:error, %{error: "NVIDIA API error", status: status, detail: response_body}}

      {:error, exception} ->
        {:error, %{error: "NVIDIA request failed", detail: Exception.message(exception)}}
    end
  end

  defp parse(%{"choices" => [%{"message" => %{"content" => text}} | _]}) do
    cleaned = Prompt.strip_code_fences(text)

    case Jason.decode(cleaned) do
      {:ok, parsed} -> {:ok, Map.put(parsed, "mock", false)}
      {:error, _} -> {:error, %{error: "Model returned non-JSON output.", raw: text}}
    end
  end

  defp parse(other), do: {:error, %{error: "Unexpected NVIDIA response shape", detail: other}}
end
