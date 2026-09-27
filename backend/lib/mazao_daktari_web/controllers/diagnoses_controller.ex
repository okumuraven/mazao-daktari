defmodule MazaoDaktariWeb.DiagnosesController do
  use MazaoDaktariWeb, :controller

  alias MazaoDaktari.Diagnoses

  @doc "GET /api/diagnoses — the signed-in user's diagnosis history, most recent first."
  def index(conn, _params) do
    diagnoses = Diagnoses.list_for_user(conn.assigns.current_user)
    json(conn, %{diagnoses: Enum.map(diagnoses, &diagnosis_json/1)})
  end

  defp diagnosis_json(d) do
    %{
      id: d.id,
      description: d.description,
      crop: d.crop,
      issue: d.issue,
      confidence: d.confidence,
      urgency: d.urgency,
      symptoms: d.symptoms,
      treatment: d.treatment,
      prevention: d.prevention,
      language: d.language,
      mock: d.mock,
      inserted_at: d.inserted_at
    }
  end
end
