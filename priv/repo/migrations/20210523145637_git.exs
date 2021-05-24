defmodule GitLookup.Repo.Migrations.Git do
  use Ecto.Migration

  def change do
    create table(:lookup_results) do
      add :language, :string
      add :payload, :map, default: %{}

      timestamps()
    end
  end
end
