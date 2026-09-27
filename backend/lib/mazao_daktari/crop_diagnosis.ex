defmodule MazaoDaktari.CropDiagnosis do
  @moduledoc """
  Diagnoses a crop problem from an optional photo and/or text description.

  Tries the `MazaoDaktari.AI.KeyRing` pool (Gemini keys, then NVIDIA) in
  round-robin order: a rate-limited (HTTP 429) key is put in cooldown and
  the next pool entry is tried, up to once per configured key. If the pool
  is empty (no keys configured) or every entry is exhausted, falls back to
  a clearly-labeled mock diagnosis so the app stays demoable without live
  API access.
  """

  require Logger

  alias MazaoDaktari.AI.KeyRing
  alias MazaoDaktari.AI.Providers.{Gemini, Nvidia}

  @type language :: String.t()

  def mock_mode?, do: KeyRing.pool_size() == 0

  @doc "Pool size only, for the health endpoint — never exposes keys or providers."
  def pool_size, do: KeyRing.pool_size()

  @spec diagnose(String.t(), binary() | nil, String.t() | nil, language()) ::
          {:ok, map()} | {:error, map()}
  def diagnose(description, image_binary, image_mime_type, language) do
    attempt(description, image_binary, image_mime_type, language, KeyRing.pool_size())
  end

  defp attempt(_description, _image_binary, _mime, language, 0) do
    {:ok, mock_diagnosis(language)}
  end

  defp attempt(description, image_binary, mime, language, attempts_left) do
    case KeyRing.checkout() do
      :empty ->
        {:ok, mock_diagnosis(language)}

      {:ok, %{provider: provider, key: key} = entry} ->
        module = provider_module(provider)

        case module.diagnose(key, description, image_binary, mime, language) do
          {:ok, result} ->
            {:ok, result}

          {:error, :rate_limited} ->
            Logger.warning("#{provider} key rate-limited, rotating to next pool entry")
            KeyRing.report_rate_limited(entry)
            attempt(description, image_binary, mime, language, attempts_left - 1)

          {:error, reason} ->
            # Transient/model error on this key - move to the next pool entry
            # rather than failing the whole request outright.
            Logger.warning("#{provider} diagnosis attempt failed: #{inspect(reason)}")
            attempt(description, image_binary, mime, language, attempts_left - 1)
        end
    end
  end

  defp provider_module(:gemini), do: Gemini
  defp provider_module(:nvidia), do: Nvidia

  defp mock_diagnosis("sw") do
    %{
      "mock" => true,
      "crop" => "Mahindi (nadhani)",
      "issue" => "Kuvu ya majani (mfano)",
      "confidence" => "low",
      "symptoms" => [
        "Madoa ya kahawia kwenye majani",
        "Majani kunyauka kuanzia chini"
      ],
      "treatment" => [
        "Ondoa na choma majani yaliyoathirika",
        "Tumia dawa ya kuvu inayopatikana eneo lako",
        "Hakikisha nafasi nzuri kati ya mimea kwa mzunguko wa hewa"
      ],
      "prevention" => [
        "Zungusha mazao kila msimu",
        "Tumia mbegu zisizo na magonjwa"
      ],
      "urgency" => "medium",
      "language" => "sw",
      "note" =>
        "MOCK RESPONSE — set GEMINI_API_KEYS/NVIDIA_API_KEY on the server to get real AI diagnoses (or the whole pool is temporarily rate-limited). This shape matches the live response exactly."
    }
  end

  defp mock_diagnosis(_en) do
    %{
      "mock" => true,
      "crop" => "Maize (guess)",
      "issue" => "Leaf blight (example)",
      "confidence" => "low",
      "symptoms" => [
        "Brown lesions on leaves",
        "Wilting starting from lower leaves"
      ],
      "treatment" => [
        "Remove and burn affected leaves",
        "Apply a locally available fungicide",
        "Improve plant spacing for airflow"
      ],
      "prevention" => [
        "Rotate crops each season",
        "Use certified disease-free seed"
      ],
      "urgency" => "medium",
      "language" => "en",
      "note" =>
        "MOCK RESPONSE — set GEMINI_API_KEYS/NVIDIA_API_KEY on the server to get real AI diagnoses (or the whole pool is temporarily rate-limited). This shape matches the live response exactly."
    }
  end
end
