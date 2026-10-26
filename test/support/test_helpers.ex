defmodule KapsoEx.TestHelpers do
  @moduledoc false

  @doc "A client whose requests go to the `Req.Test` stub named `KapsoEx`."
  def client(opts \\ []) do
    [api_key: "test_key", req_options: [plug: {Req.Test, KapsoEx}, retry: false]]
    |> Keyword.merge(opts)
    |> KapsoEx.new()
  end

  @doc """
  Stubs every request with a JSON `response` (and `status`) and sends
  `{:request, request}` to the test process for each request received.
  """
  def capture(response \\ %{}, status \\ 200) do
    test_pid = self()

    Req.Test.stub(KapsoEx, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      send(test_pid, {
        :request,
        %{
          method: conn.method,
          path: conn.request_path,
          query: URI.decode_query(conn.query_string),
          headers: Map.new(conn.req_headers),
          body: body,
          json: decode(body)
        }
      })

      conn
      |> Plug.Conn.put_status(status)
      |> Req.Test.json(response)
    end)
  end

  defp decode(""), do: nil

  defp decode(body) do
    case Jason.decode(body) do
      {:ok, json} -> json
      {:error, _} -> nil
    end
  end
end
