defmodule GitLookupWeb.SearchLive do
  use GitLookupWeb, :live_view

  alias GitLookup.Results
  alias GitLookup.Results.Internal

  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign(:changeset, Results.changeset())
      |> assign(:results, %{})}
  end

  def handle_event("save", %{"results" => language}, socket) do
    case Internal.create(language) do
      {:error, %Ecto.Changeset{} = changeset} ->
        changeset = %{changeset | action: :insert}


        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> assign(:results, Internal.fetch_payload(language))}

      {:ok, changeset} ->


        %{changeset: %Ecto.Changeset{changes: %{payload: %{items: results}}}} = changeset

        {:noreply,
          socket
          |> assign(:changeset, Results.changeset())
          |> assign(:results, Enum.at(results, 0))}

    end
  end
end
