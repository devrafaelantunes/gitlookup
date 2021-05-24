defmodule GitLookup do

  def call(language, per_page, headers \\ []) do
    "https://api.github.com/search/repositories?q=language:#{language}&sort=stars&order_by=desc&per_page=#{per_page}"

    |> HTTPoison.get(headers)
    |> case do
         {:ok, %{body: raw, status_code: code, headers: headers}} ->
           {code, raw, headers}
         {:error, %{reason: reason}} -> {:error, reason, []}
      end
  end

  def content_type({ok, body, headers}) do
    {ok, body, content_type(headers)}
  end

  def content_type([]), do: "application/json"

  def content_type([{"Content-Type", val} | _]) do
    val
    |> String.split(";")
    |> List.first
  end

  def content_type([_ | t]), do: content_type(t)

  def decode({_ok, body, "application/json"}) do
    body
    |> Poison.decode(keys: :atoms)
    |> case do
         {:ok, %{items: items} = _parsed} -> %{items: items}
         _ -> {:error, body}
       end
  end

  def decode({ok, body, _}), do: {ok, body}

  def get(language, per_page, headers \\ []) do
      language
      |> call(per_page, headers)
      |> content_type
      |> decode
  end
end
