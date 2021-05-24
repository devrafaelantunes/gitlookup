defmodule GitLookup.Repo do
  use Ecto.Repo,
    otp_app: :git_lookup,
    adapter: Ecto.Adapters.Postgres
end
