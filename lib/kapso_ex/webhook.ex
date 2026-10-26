defmodule KapsoEx.Webhook do
  @moduledoc """
  Verifies and decodes webhooks sent by Kapso.

  Kapso signs every webhook (project webhooks and both `kapso` and `meta`
  kind phone number webhooks) with an HMAC-SHA256 of the **raw request body**
  using the webhook's `secret_key`, hex encoded, in the `X-Webhook-Signature`
  header.

  Other useful headers:

    * `X-Webhook-Event` - event name, for example `whatsapp.message.received`.
    * `X-Idempotency-Key` - unique per delivery; use it to drop duplicates,
      since webhooks can be delivered more than once.
    * `X-Webhook-Batch: true` - the body is a batch envelope
      (`%{"batch" => true, "data" => [...]}`); see `payloads/1`.

  ## Phoenix example

  The signature must be computed over the exact bytes Kapso sent, so keep a
  copy of the raw body with `KapsoEx.Webhook.CacheBodyReader`:

      # endpoint.ex
      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        body_reader: {KapsoEx.Webhook.CacheBodyReader, :read_body, []},
        json_decoder: Jason

      # controller
      def create(conn, _params) do
        raw_body = KapsoEx.Webhook.CacheBodyReader.raw_body(conn)
        [signature] = get_req_header(conn, "x-webhook-signature")
        [event] = get_req_header(conn, "x-webhook-event")

        case KapsoEx.Webhook.construct_event(raw_body, signature, webhook_secret()) do
          {:ok, body} ->
            for payload <- KapsoEx.Webhook.payloads(body), do: MyApp.handle(event, payload)
            send_resp(conn, 200, "ok")

          {:error, _reason} ->
            send_resp(conn, 401, "invalid signature")
        end
      end

  Respond within 10 seconds and move heavy work to a background job.
  """

  @doc """
  Returns `true` when `signature` (the `X-Webhook-Signature` header) matches
  the HMAC-SHA256 of `payload` with `secret`.

  The comparison runs in constant time. A `nil` or malformed signature
  returns `false`.
  """
  @spec verify_signature(binary(), String.t() | nil, String.t()) :: boolean()
  def verify_signature(payload, signature, secret)
      when is_binary(payload) and is_binary(secret) do
    is_binary(signature) and secure_compare(hmac_hex(payload, secret), String.downcase(signature))
  end

  @doc """
  Verifies a webhook sent **directly by Meta** (not forwarded by Kapso),
  using the `X-Hub-Signature-256` header (`"sha256=<hex>"`) and your Meta
  app secret.
  """
  @spec verify_meta_signature(binary(), String.t() | nil, String.t()) :: boolean()
  def verify_meta_signature(payload, "sha256=" <> signature, app_secret),
    do: verify_signature(payload, signature, app_secret)

  def verify_meta_signature(_payload, _signature, _app_secret), do: false

  @doc """
  Verifies the signature and decodes the JSON body.

  Returns `{:error, :invalid_signature}` when the signature does not match
  and `{:error, %Jason.DecodeError{}}` when the body is not valid JSON.
  """
  @spec construct_event(binary(), String.t() | nil, String.t()) ::
          {:ok, map()} | {:error, :invalid_signature | Jason.DecodeError.t()}
  def construct_event(payload, signature, secret) do
    if verify_signature(payload, signature, secret) do
      Jason.decode(payload)
    else
      {:error, :invalid_signature}
    end
  end

  @doc """
  Returns the list of event payloads in a decoded webhook body.

  Buffered `whatsapp.message.received` webhooks arrive as a batch envelope
  with the payloads under `"data"`; every other webhook carries a single
  payload.

  ## Examples

      iex> KapsoEx.Webhook.payloads(%{"batch" => true, "data" => [%{"message" => 1}, %{"message" => 2}]})
      [%{"message" => 1}, %{"message" => 2}]

      iex> KapsoEx.Webhook.payloads(%{"message" => 1})
      [%{"message" => 1}]
  """
  @spec payloads(map()) :: [map()]
  def payloads(%{"batch" => true, "data" => data}) when is_list(data), do: data
  def payloads(%{} = body), do: [body]

  defp hmac_hex(payload, secret) do
    :hmac
    |> :crypto.mac(:sha256, secret, payload)
    |> Base.encode16(case: :lower)
  end

  defp secure_compare(left, right) when byte_size(left) == byte_size(right) do
    left
    |> :binary.bin_to_list()
    |> Enum.zip(:binary.bin_to_list(right))
    |> Enum.reduce(0, fn {x, y}, acc -> Bitwise.bor(acc, Bitwise.bxor(x, y)) end)
    |> Kernel.==(0)
  end

  defp secure_compare(_left, _right), do: false
end
