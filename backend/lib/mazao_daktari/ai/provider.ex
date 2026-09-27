defmodule MazaoDaktari.AI.Provider do
  @moduledoc """
  Behaviour every AI backend (Gemini, NVIDIA, ...) implements, so
  `MazaoDaktari.CropDiagnosis` can retry across the key ring without caring
  which provider it's talking to.
  """

  @type language :: String.t()
  @type diagnosis :: map()

  @callback diagnose(
              api_key :: String.t(),
              description :: String.t(),
              image_binary :: binary() | nil,
              mime_type :: String.t() | nil,
              language :: language()
            ) :: {:ok, diagnosis()} | {:error, :rate_limited} | {:error, map()}
end
