defmodule KapsoEx do
  @moduledoc """
  Elixir client for the [Kapso](https://kapso.ai) API.

  Kapso exposes three HTTP APIs that share one project API key:

    * **WhatsApp** (`KapsoEx.WhatsApp.*`) - a proxy of Meta's WhatsApp Cloud
      API: send messages, manage templates, media, flows, calls and more.
      Request and response shapes mirror Meta's Graph API.
    * **Platform** (`KapsoEx.Platform.*`) - customers, setup links, phone
      numbers, broadcasts, webhooks, contacts, conversations, project events
      and the rest of the Kapso platform.
    * **Workflows** (`KapsoEx.Workflows`, `KapsoEx.Functions`) and
      **Kapso Agent** (`KapsoEx.Agent.*`) - automation runs, serverless
      functions and agent runs.

  Inbound webhooks are verified with `KapsoEx.Webhook`.

  ## Usage

      client = KapsoEx.new(api_key: System.fetch_env!("KAPSO_API_KEY"))

      {:ok, %{"messages" => [%{"id" => wamid}]}} =
        KapsoEx.WhatsApp.Messages.send_text(client, "647015955153740", "56961567267", "Hola!")

      {:ok, %{"data" => customers, "meta" => meta}} =
        KapsoEx.Platform.Customers.list(client, per_page: 50)

  Every function returns `{:ok, body}` with the decoded JSON body as returned
  by Kapso (string keys, `data`/`meta`/`paging` included), or
  `{:error, %KapsoEx.Error{}}`. Endpoints that answer with no content return
  `{:ok, nil}`.

  Use `KapsoEx.Pagination.stream/2` to iterate over every page of a list
  endpoint.
  """

  alias KapsoEx.{Client, Request}

  @doc """
  Builds a client. See `KapsoEx.Client` for every option.

  Options not given here are read from the application environment:

      # config/runtime.exs
      config :kapso_ex, api_key: System.fetch_env!("KAPSO_API_KEY")

  ## Examples

      KapsoEx.new(api_key: "kapso_live_...")

      # Longer timeout and automatic retries for every method on 429/5xx
      KapsoEx.new(api_key: "...", req_options: [receive_timeout: 30_000, retry: :transient])

      # Talk to Meta's Graph API directly with a system user token
      KapsoEx.new(access_token: "EAAG...", whatsapp_base_url: "https://graph.facebook.com/v24.0")
  """
  @spec new(keyword()) :: Client.t()
  defdelegate new(opts \\ []), to: Client

  @doc """
  Sends a request to any Kapso endpoint, for paths this library does not
  wrap yet.

  `api` is `:whatsapp` or `:platform` and selects the base URL and auth
  header. `path` is relative to the base URL, either as a string or as a list
  of segments (each one URL-encoded).

  ## Options

    * `:query` - query params as a map or keyword list.
    * `:json` - request body, encoded as JSON.
    * `:form_multipart` - multipart body (see `Req.Steps.encode_body/1`).
    * `:headers` - extra request headers, such as `[{"idempotency-key", key}]`.

  ## Examples

      KapsoEx.request(client, :platform, :get, "/customers", query: [per_page: 5])

      KapsoEx.request(client, :whatsapp, :post, ["123", "messages"],
        json: %{messaging_product: "whatsapp", to: "56961567267", type: "text", text: %{body: "Hi"}}
      )
  """
  @spec request(Client.t(), :whatsapp | :platform, atom(), String.t() | list(), keyword()) ::
          {:ok, term()} | {:error, KapsoEx.Error.t()}
  def request(%Client{} = client, api, method, path, opts \\ [])
      when api in [:whatsapp, :platform] do
    opts = Keyword.take(opts, [:query, :json, :form_multipart, :headers])
    Request.request(client, api, method, path, opts)
  end
end
