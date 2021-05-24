defmodule GitLookup.Results do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lookup_results" do
    field :language, :string
    field :payload, :map

    timestamps()
  end

  def changeset(attrs \\ %{}) do
    %__MODULE__{}
    |> cast(attrs, [:language, :payload])
    |> validate_required([:language, :payload])
  end
end

defmodule GitLookup.Results.Query do
  import Ecto.Query
  alias GitLookup.Results

  def language(language) do
    from r in Results,
      where: r.language == ^language,
      select: r
  end
end
