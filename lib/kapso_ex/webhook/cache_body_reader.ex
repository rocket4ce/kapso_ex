if Code.ensure_loaded?(Plug.Conn) do
  defmodule KapsoEx.Webhook.CacheBodyReader do
    @moduledoc """
    A `Plug.Parsers` body reader that keeps the raw request body, which is
    needed to verify webhook signatures after the JSON has been parsed.

        plug Plug.Parsers,
          parsers: [:json],
          pass: ["*/*"],
          body_reader: {KapsoEx.Webhook.CacheBodyReader, :read_body, []},
          json_decoder: Jason

    Then read it back with `raw_body/1`. Only available when `:plug` is a
    dependency of your application.
    """

    @doc "Reads the body like `Plug.Conn.read_body/2` and stores a copy in `conn.private`."
    @spec read_body(Plug.Conn.t(), keyword()) ::
            {:ok, binary(), Plug.Conn.t()} | {:more, binary(), Plug.Conn.t()} | {:error, term()}
    def read_body(conn, opts) do
      case Plug.Conn.read_body(conn, opts) do
        {status, body, conn} when status in [:ok, :more] ->
          chunks = conn.private[:kapso_ex_raw_body] || []
          {status, body, Plug.Conn.put_private(conn, :kapso_ex_raw_body, [chunks | body])}

        error ->
          error
      end
    end

    @doc "Returns the raw body cached by `read_body/2`, or `nil` when it was not read."
    @spec raw_body(Plug.Conn.t()) :: binary() | nil
    def raw_body(conn) do
      if chunks = conn.private[:kapso_ex_raw_body], do: IO.iodata_to_binary(chunks)
    end
  end
end
