defmodule MazaoDaktariWeb.DiagnosisController do
  use MazaoDaktariWeb, :controller

  require Logger

  alias MazaoDaktari.CropDiagnosis
  alias MazaoDaktari.Diagnoses

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
            maybe_save_history(conn.assigns[:current_user], description, result)
            json(conn, result)

          {:error, error} ->
            conn
            |> put_status(:bad_gateway)
            |> json(error)
        end
    end
  end

  # Anonymous requests are diagnosed but never persisted - history is an
  # account feature, not a side effect of calling the API.
  defp maybe_save_history(nil, _description, _result), do: :ok

  defp maybe_save_history(user, description, result) do
    case Diagnoses.save(user, description, result) do
      {:ok, _diagnosis} ->
        :ok

      {:error, changeset} ->
        Logger.warning("Failed to save diagnosis history: #{inspect(changeset.errors)}")
        :ok
    end
  end

  defp read_upload(%Plug.Upload{path: path, content_type: content_type}) do
    {File.read!(path), content_type}
  end

  defp read_upload(_), do: {nil, nil}
end
