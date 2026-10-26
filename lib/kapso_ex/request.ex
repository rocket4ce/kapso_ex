defmodule KapsoEx.Request do
  @moduledoc false

  alias KapsoEx.{Client, Error}

  @user_agent "kapso_ex/#{Mix.Project.config()[:version]}"

  @type api :: :whatsapp | :platform
  @type path :: String.t() | [String.Chars.t()]
  @type result :: {:ok, term()} | {:error, Error.t()}

  @spec get(Client.t(), api(), path(), keyword()) :: result()
  def get(client, api, path, opts \\ []), do: request(client, api, :get, path, opts)

  @spec post(Client.t(), api(), path(), keyword()) :: result()
  def post(client, api, path, opts \\ []), do: request(client, api, :post, path, opts)

  @spec put(Client.t(), api(), path(), keyword()) :: result()
  def put(client, api, path, opts \\ []), do: request(client, api, :put, path, opts)

  @spec patch(Client.t(), api(), path(), keyword()) :: result()
  def patch(client, api, path, opts \\ []), do: request(client, api, :patch, path, opts)

  @spec delete(Client.t(), api(), path(), keyword()) :: result()
  def delete(client, api, path, opts \\ []), do: request(client, api, :delete, path, opts)

  @doc """
  Sends a request and normalizes the result.

  Options:

    * `:query` - query params (map or keyword); `nil` values are dropped and
      dates are encoded as ISO 8601.
    * `:json` - request body, encoded as JSON. A top-level keyword list is
      converted to a map.
    * `:form_multipart` - multipart body, passed to `Req` as is.
    * `:headers` - extra request headers.
    * `:decode` - set to `false` to get the raw response body.
  """
  @spec request(Client.t(), api(), atom(), path(), keyword()) :: result()
  def request(%Client{} = client, api, method, path, opts \\ []) do
    request_opts =
      [method: method, url: build_path(path), params: encode_query(opts[:query])]
      |> put_body(opts)
      |> put_decode(opts)
      |> put_headers(opts[:headers])

    client
    |> new(api)
    |> Req.request(request_opts)
    |> handle_response()
  end

  @doc """
  Fetches an absolute URL (such as a media `download_url`) using the client's
  `:req_options`, without auth headers and without decoding the body.
  """
  @spec fetch_url(Client.t(), String.t()) :: result()
  def fetch_url(%Client{} = client, url) when is_binary(url) do
    [headers: [{"user-agent", @user_agent}]]
    |> Req.new(client.req_options)
    |> Req.request(url: url, decode_body: false)
    |> handle_response()
  end

  @doc "Converts a keyword list or map of attributes into a JSON-encodable map."
  @spec to_map(map() | keyword() | nil) :: map()
  def to_map(nil), do: %{}
  def to_map(%{} = map), do: map
  def to_map(list) when is_list(list), do: Map.new(list)

  @doc "Wraps attributes in the root key some Platform endpoints expect."
  @spec wrap(map() | keyword(), atom()) :: map()
  def wrap(attrs, key), do: %{key => to_map(attrs)}

  defp new(client, api) do
    [base_url: base_url(client, api), headers: [{"user-agent", @user_agent} | auth(client, api)]]
    |> Req.new(client.req_options)
  end

  defp base_url(client, :whatsapp), do: client.whatsapp_base_url
  defp base_url(client, :platform), do: client.platform_base_url

  defp auth(%Client{access_token: token}, :whatsapp) when is_binary(token),
    do: [{"authorization", "Bearer " <> token}]

  defp auth(%Client{api_key: key}, _api) when is_binary(key), do: [{"x-api-key", key}]

  defp auth(_client, api) do
    raise ArgumentError, "the #{api} API requires an :api_key, but the client has none"
  end

  defp build_path(path) when is_binary(path), do: path

  defp build_path(segments) when is_list(segments) do
    Enum.map_join(segments, fn segment ->
      "/" <> URI.encode(to_string(segment), &URI.char_unreserved?/1)
    end)
  end

  defp encode_query(nil), do: []

  defp encode_query(query) do
    for {key, value} <- query, not is_nil(value), do: {key, encode_value(value)}
  end

  defp encode_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp encode_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp encode_value(%Date{} = value), do: Date.to_iso8601(value)
  defp encode_value(value), do: value

  defp put_body(request_opts, opts) do
    cond do
      Keyword.has_key?(opts, :json) ->
        [{:json, json_body(opts[:json])} | request_opts]

      Keyword.has_key?(opts, :form_multipart) ->
        [{:form_multipart, opts[:form_multipart]} | request_opts]

      true ->
        request_opts
    end
  end

  defp json_body(list) when is_list(list) do
    if Keyword.keyword?(list), do: Map.new(list), else: list
  end

  defp json_body(body), do: body

  defp put_decode(request_opts, opts) do
    if Keyword.get(opts, :decode, true),
      do: request_opts,
      else: [{:decode_body, false} | request_opts]
  end

  defp put_headers(request_opts, nil), do: request_opts
  defp put_headers(request_opts, []), do: request_opts
  defp put_headers(request_opts, headers), do: [{:headers, headers} | request_opts]

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) when status in 200..299,
    do: {:ok, normalize_body(body)}

  defp handle_response({:ok, %Req.Response{} = response}),
    do: {:error, Error.from_response(response)}

  defp handle_response({:error, exception}), do: {:error, Error.from_exception(exception)}

  defp normalize_body(""), do: nil
  defp normalize_body(body), do: body
end
