defmodule MazaoDaktariWeb.DiagnosisController do
  use MazaoDaktariWeb, :controller

  alias MazaoDaktari.CropDiagnosis

  def health(conn, _params) do
    json(conn, %{
      ok: true,
      mock_mode: CropDiagnosis.mock_mode?(),
      key_pool_size: CropDiagnosis.pool_size()
    })
  end

  def diagnose(conn, params) do
    description = String.trim(Map.get(params, "description", "") || "")
    language = if Map.get(params, "language") == "sw", do: "sw", else: "en"
    upload = Map.get(params, "image")

    cond do
      description == "" and is_nil(upload) ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Provide a photo, a description, or both."})

      true ->
        {image_binary, mime_type} = read_upload(upload)

        case CropDiagnosis.diagnose(description, image_binary, mime_type, language) do
          {:ok, result} ->
            json(conn, result)

          {:error, error} ->
            conn
            |> put_status(:bad_gateway)
            |> json(error)
        end
    end
  end

  defp read_upload(%Plug.Upload{path: path, content_type: content_type}) do
    {File.read!(path), content_type}
  end

  defp read_upload(_), do: {nil, nil}
end
