defmodule GitLookup.Results.Internal do
  alias GitLookup.{Repo, Results, Results.Query, Utils}
  alias Ecto.Multi
  import Ecto.Changeset

  #time limit in minutes
  @time_limit 90

  def create(language) do
    with %Ecto.Changeset{} = changeset <- Results.changeset(language, %{}),
        {:ok, payload} <- check_existence(language),
        {:ok, :compare, :on_time, _} <- compare_datetime(payload, changeset),
        {:ok, :compare, new_payload, _} <- compare_results(language, payload, changeset) do

          insert(payload, new_payload, language)

      else
        {nil, language} -> insert(language, GitLookup.get(language))
        {:error, :compare, {changeset, time_difference}, _} -> add_error(changeset, :results, "wait for #{time_difference}")
        {:error, :compare, changeset, _} -> add_error(changeset, :results, "the same")
      end
  end

  defp check_existence(language) do
    IO.puts("Verificando existencia...")

    payload =
      Query.language(language)
      |> Repo.one()

    case payload do
      nil -> {nil, language}
      _ -> {:ok, payload}
    end
  end

  defp compare_datetime(%Results{inserted_at: datetime} = _result, changeset) do
    Multi.new()
    |> Multi.run(:inserted_datetime, fn _, _ ->
      {:ok, DateTime.from_naive(datetime, "Etc/UTC")}
    end)
    |> Multi.run(:time_difference, fn _, %{inserted_datetime: {:ok, inserted_datetime}} ->
      IO.inspect(inserted_datetime)
      {:ok, DateTime.diff(DateTime.utc_now, inserted_datetime) / 60}
    end)
    |> Multi.run(:compare, fn _, %{time_difference: time_difference} ->
      if time_difference > @time_limit do
        {:ok, :on_time}
      else
        {:error, {changeset, time_difference}}
      end
    end)
    |> Repo.transaction()
  end

  defp compare_results(language, %{payload: %{"items" => [payload_db]}} = _result, changeset) do
    Multi.new()
    |> Multi.run(:payload, fn _, _ ->
      %{items: [payload]} = GitLookup.get(language)

      {:ok, payload}
    end)
    |> Multi.run(:compare, fn _, %{payload: payload} ->
      if payload == Utils.atomify_map(payload_db) do
        {:error, changeset}
      else
        {:ok, %{items: [payload]}}
      end
    end)
    |> Repo.transaction()
  end

  defp insert(language, attrs) do
    Multi.new()
    |> Multi.run(:changeset, fn _, _ ->
      {:ok, Results.changeset(language, attrs)}
    end)
    |> Multi.insert(:insert, fn %{changeset: changeset} ->
      changeset
    end)
    |> Repo.transaction()
  end

  defp insert(result, payload, language) do
    Multi.new()
    |> Multi.delete(:delete, result)
    |> Multi.run(:changeset, fn _, _ ->
      {:ok, Results.changeset(language, payload)}
    end)
    |> Multi.insert(:insert, fn %{changeset: changeset} ->
      changeset
    end)
    |> Repo.transaction()
  end
end
