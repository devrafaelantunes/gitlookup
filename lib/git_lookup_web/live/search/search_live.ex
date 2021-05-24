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

  def handle_event("save", %{"results" => results}, socket) do
    case Internal.create(results) do
      {:error, %Ecto.Changeset{} = changeset} ->
        changeset = %{changeset | action: :insert}
        %{"language" => language} = results


        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> assign(:results, Internal.fetch_payload(language))
          |> assign(:language, language)}

      {:ok, changeset} ->
        %{"language" => language} = results
        %{changeset: %Ecto.Changeset{changes: %{payload: %{items: results}}}} = changeset

        {:noreply,
          socket
          |> assign(:changeset, Results.changeset())
          |> assign(:results, Enum.at(results, 0))
          |> assign(:language, language)}

    end
  end
end
