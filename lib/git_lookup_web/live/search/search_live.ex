defmodule GitLookupWeb.SearchLive do
  use GitLookupWeb, :live_view

  alias GitLookup.Results
  alias GitLookup.Results.Internal

  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign(:changeset, Results.changeset())
      |> assign(:results, %{})
      |> assign(:language, nil)}
  end

  def handle_event("save", %{"results" => values}, socket) do
    case Internal.create(values) do
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect("ERROU RAPAZZZ")
        changeset = %{changeset | action: :insert}
        %{"language" => language} = values

        IO.inspect(language)

        IO.inspect(Internal.fetch_payload(language))

        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> assign(:results, Internal.fetch_payload(language))
          |> assign(:language, language)}

      {:error, :empty, %Ecto.Changeset{} = changeset} ->
        changeset = %{changeset | action: :insert}

        {:noreply,
          socket
          |> assign(:changeset, changeset)}

      {:ok, changeset} ->
        IO.inspect("DEU OK")
        %{changeset: %Ecto.Changeset{changes: %{payload: %{items: results}}}} = changeset
        %{"language" => language} = values

        IO.inspect(language)
        IO.inspect(values)
        IO.inspect(results)


        {:noreply,
          socket
          |> assign(:changeset, Results.changeset())
          |> assign(:results, results)
          |> assign(:language, language)}


    end
  end
end
