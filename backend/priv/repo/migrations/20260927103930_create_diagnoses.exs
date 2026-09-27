defmodule MazaoDaktari.Repo.Migrations.CreateDiagnoses do
  use Ecto.Migration

  def change do
    create table(:diagnoses) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :description, :text
      add :crop, :string
      add :issue, :string
      add :confidence, :string
      add :urgency, :string
      add :symptoms, {:array, :string}, default: []
      add :treatment, {:array, :string}, default: []
      add :prevention, {:array, :string}, default: []
      add :language, :string
      add :mock, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:diagnoses, [:user_id])
    create index(:diagnoses, [:user_id, :inserted_at])
  end
end
