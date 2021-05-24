defmodule GitLookup.Results.Internal do
  alias GitLookup.{Repo, Results, Results.Query, Utils}
  alias Ecto.Multi
  import Ecto.Changeset

  #time limit in minutes
  @time_limit 1

  def create(%{"language" => language, "per_page" => per_page}) do
    with %Ecto.Changeset{} = changeset <- Results.changeset(%{language: language, payload: %{}}),
        {:ok, payload} <- check_existence(language),
        {:ok, :on_time} <- compare_datetime(payload, changeset),
        {:ok, :not_equal, new_payload} <- compare_results(language, payload, changeset, per_page) do

          insert(payload, new_payload, language)

      else
        {nil, language} -> insert(language, GitLookup.get(language, per_page))
        {:error, :too_early, changeset} -> {:error, add_error(changeset, :language, "Results retrived from DB. Please, wait before making another request")}
        {:error, :equal, changeset} -> {:error, add_error(changeset, :language, "Results retrived from DB. The results did not change")}
      end
  end

  defp check_existence(language) do
    IO.puts("Checando a existencia...")

    payload =
      Query.language(language)
      |> Repo.one()

    case payload do
      nil -> {nil, language}
      _ -> {:ok, payload}
    end
  end

  defp compare_datetime(%Results{inserted_at: datetime} = _result, changeset) do
    IO.puts("Comparando horario...")

    {:ok, inserted_datetime} =
      DateTime.from_naive(datetime, "Etc/UTC")

    time_difference =
      DateTime.diff(DateTime.utc_now, inserted_datetime) / 60

    if time_difference > @time_limit do
      {:ok, :on_time}
    else
      IO.puts("Ainda falta")
      {:error, :too_early, changeset}
    end
  end

  defp compare_results(language, %{payload: %{"items" => payload_db}} = _result, changeset, per_page) do
    %{items: payload} = GitLookup.get(language, per_page)

    payload_db = Enum.map(payload_db, fn payload -> Utils.atomify_map(payload) end)

    IO.inspect("PAYLOAD DBDBDBDBDBDB")
    IO.inspect(payload_db)

    IO.inspect("pAYLOAD NORMALMALMLA")
    IO.inspect(payload)


    if payload == payload_db do
      IO.puts("Sao iguais")
      #{:ok, :not_equal, %{items: [payload]}}
      {:error, :equal, changeset}
    else
      IO.puts("Diferentoes")
      {:ok, :not_equal, %{items: payload}}
    end
  end

  defp insert(language, items) do
    IO.puts("Inserindo...")
    if language == "" do
      changeset = Results.changeset(%{language: language, payload: items})
      {:error, :empty, changeset}
    else
      Multi.new()
      |> Multi.run(:changeset, fn _, _ ->
        {:ok, Results.changeset(%{language: language, payload: items})}
      end)
      |> Multi.insert(:insert, fn %{changeset: changeset} ->
        changeset
      end)
      |> Repo.transaction()
    end
  end

  defp insert(result, items, language) do
    IO.puts("Inserindo e deletando...")

    Multi.new()
    |> Multi.delete(:delete, result)
    |> Multi.run(:changeset, fn _, _ ->
      {:ok, Results.changeset(%{language: language, payload: items})}
    end)
    |> Multi.insert(:insert, fn %{changeset: changeset} ->
      changeset
    end)
    |> Repo.transaction()
  end

  def fetch_payload(language) do
    payload =
      Query.language(language)
      |> Repo.one()

  %{payload: %{"items" => payload_db}} = payload

  Enum.map(payload_db, fn payload -> Utils.atomify_map(payload) end)

  end
end
