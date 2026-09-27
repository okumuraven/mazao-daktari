defmodule MazaoDaktari.Diagnoses do
  @moduledoc """
  Persisted diagnosis history, scoped to a signed-in user. A diagnosis for
  an anonymous (not signed-in) request is never saved — see
  `MazaoDaktariWeb.DiagnosisController`.
  """

  import Ecto.Query, warn: false

  alias MazaoDaktari.Repo
  alias MazaoDaktari.Diagnoses.Diagnosis
  alias MazaoDaktari.Accounts.User

  @doc "Persists a diagnosis result (a plain map, as returned by MazaoDaktari.CropDiagnosis) for a user."
  @spec save(User.t(), String.t() | nil, map()) ::
          {:ok, Diagnosis.t()} | {:error, Ecto.Changeset.t()}
  def save(%User{id: user_id}, description, result) do
    attrs = %{
      user_id: user_id,
      description: description,
      crop: Map.get(result, "crop"),
      issue: Map.get(result, "issue"),
      confidence: Map.get(result, "confidence"),
      urgency: Map.get(result, "urgency"),
      symptoms: Map.get(result, "symptoms", []),
      treatment: Map.get(result, "treatment", []),
      prevention: Map.get(result, "prevention", []),
      language: Map.get(result, "language"),
      mock: Map.get(result, "mock", false)
    }

    %Diagnosis{}
    |> Diagnosis.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Lists a user's diagnosis history, most recent first."
  @spec list_for_user(User.t(), keyword()) :: [Diagnosis.t()]
  def list_for_user(%User{id: user_id}, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Diagnosis
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end
end
