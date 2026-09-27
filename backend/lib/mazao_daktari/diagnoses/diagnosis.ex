defmodule MazaoDaktari.Diagnoses.Diagnosis do
  use Ecto.Schema
  import Ecto.Changeset

  schema "diagnoses" do
    field(:description, :string)
    field(:crop, :string)
    field(:issue, :string)
    field(:confidence, :string)
    field(:urgency, :string)
    field(:symptoms, {:array, :string}, default: [])
    field(:treatment, {:array, :string}, default: [])
    field(:prevention, {:array, :string}, default: [])
    field(:language, :string)
    field(:mock, :boolean, default: false)

    belongs_to(:user, MazaoDaktari.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @type t :: %__MODULE__{}

  @fields [
    :user_id,
    :description,
    :crop,
    :issue,
    :confidence,
    :urgency,
    :symptoms,
    :treatment,
    :prevention,
    :language,
    :mock
  ]

  @doc false
  def changeset(diagnosis, attrs) do
    diagnosis
    |> cast(attrs, @fields)
    |> validate_required([:user_id, :language])
  end
end
