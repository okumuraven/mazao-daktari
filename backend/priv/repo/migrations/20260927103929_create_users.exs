defmodule MazaoDaktari.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :google_sub, :string, null: false
      add :email, :string, null: false
      add :name, :string
      add :avatar_url, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:google_sub])
    create index(:users, [:email])
  end
end
