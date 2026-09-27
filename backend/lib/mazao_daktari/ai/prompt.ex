defmodule MazaoDaktari.AI.Prompt do
  @moduledoc """
  The single diagnosis instruction shared by every provider, so a swap
  between Gemini and NVIDIA never changes the shape the frontend parses.
  """

  @spec instructions(String.t(), String.t()) :: String.t()
  def instructions(description, language) do
    lang_name = if language == "sw", do: "Swahili", else: "English"
    desc = if description in [nil, ""], do: "(no description provided)", else: description

    """
    You are an agronomy assistant helping smallholder farmers in Kenya diagnose crop problems from a photo and/or description.

    Farmer's description (may be empty): "#{desc}"

    Respond with ONLY valid JSON, no markdown fences, matching exactly this shape:
    {
      "crop": "string - best guess at the crop, or 'unknown'",
      "issue": "string - short name of the likely pest/disease/deficiency",
      "confidence": "low" | "medium" | "high",
      "symptoms": ["string", "..."],
      "treatment": ["string - concrete, locally actionable steps", "..."],
      "prevention": ["string", "..."],
      "urgency": "low" | "medium" | "high",
      "language": "#{language}"
    }

    Write every string value in #{lang_name}.
    Keep treatment/prevention steps practical for a farmer with limited access to agro-chemical shops (mention low-cost/organic options where reasonable).
    If the image or description is not a crop/plant issue at all, set "crop" to "unknown" and "issue" to a short explanation of what you actually see.
    """
  end

  @spec strip_code_fences(String.t()) :: String.t()
  def strip_code_fences(text) do
    text
    |> String.replace(~r/^```json\s*/i, "")
    |> String.replace(~r/^```\s*/i, "")
    |> String.replace(~r/```\s*$/i, "")
    |> String.trim()
  end
end
