defmodule MazaoDaktari.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:google_sub, :string)
    field(:email, :string)
    field(:name, :string)
    field(:avatar_url, :string)

    has_many(:diagnoses, MazaoDaktari.Diagnoses.Diagnosis)

    timestamps(type: :utc_datetime)
  end

  @type t :: %__MODULE__{}

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:google_sub, :email, :name, :avatar_url])
    |> validate_required([:google_sub, :email])
    |> unique_constraint(:google_sub)
  end
end
