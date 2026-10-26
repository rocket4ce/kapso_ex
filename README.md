# KapsoEx

Elixir client for the [Kapso](https://kapso.ai) API: WhatsApp for developers.

It covers every endpoint in Kapso's OpenAPI specs (199 operations):

| API | Base URL | Modules |
| --- | --- | --- |
| WhatsApp (Meta Cloud API proxy) | `https://api.kapso.ai/meta/whatsapp/v24.0` | `KapsoEx.WhatsApp.*` |
| Platform | `https://api.kapso.ai/platform/v1` | `KapsoEx.Platform.*` |
| Workflows and Functions | `https://api.kapso.ai/platform/v1` | `KapsoEx.Workflows`, `KapsoEx.Workflows.*`, `KapsoEx.Functions` |
| Kapso Agent | `https://api.kapso.ai/platform/v1` | `KapsoEx.Agent.*` |

It also verifies webhook signatures (`KapsoEx.Webhook`) and paginates through list endpoints (`KapsoEx.Pagination`).

## Installation

```elixir
def deps do
  [
    {:kapso_ex, "~> 0.1.0"}
  ]
end
```

Requires Elixir 1.15+. HTTP is done with [Req](https://hexdocs.pm/req).

## Configuration

Create a client with your project API key and pass it to every call:

```elixir
client = KapsoEx.new(api_key: System.fetch_env!("KAPSO_API_KEY"))
```

Or configure it once and call `KapsoEx.new()`:

```elixir
# config/runtime.exs
config :kapso_ex, api_key: System.fetch_env!("KAPSO_API_KEY")
```

Options:

* `:api_key`: project API key, sent as `X-API-Key`.
* `:access_token`: bearer token for the WhatsApp API. Combined with `whatsapp_base_url: "https://graph.facebook.com/v24.0"`, it calls Meta directly.
* `:whatsapp_base_url`, `:platform_base_url`: override the base URLs.
* `:req_options`: merged into every request, e.g. `[receive_timeout: 30_000]`.

A client is a plain struct, so Tech Providers can build one per Kapso project.

## Responses and errors

Every function returns `{:ok, body}` with the decoded JSON exactly as Kapso sends it (string keys, including `data`, `meta` and `paging`), or `{:error, %KapsoEx.Error{}}`:

```elixir
case KapsoEx.Platform.Customers.get(client, customer_id) do
  {:ok, %{"data" => customer}} -> customer
  {:error, %KapsoEx.Error{status: 404}} -> nil
  {:error, %KapsoEx.Error{status: 429, retry_after: seconds}} -> {:retry, seconds}
end
```

`KapsoEx.Error` carries `status`, `message`, `code` (for example Meta's `131047`), `body`, `headers`, `retry_after` and `reason` (for transport errors).

By default Req retries only safe methods (`GET`, `HEAD`) on transient errors, honoring `Retry-After`, so a message is never sent twice. Pass `req_options: [retry: :transient]` to also retry `POST`s.

## WhatsApp

```elixir
alias KapsoEx.WhatsApp.{Media, Messages, Templates, TemplateComponents}

phone_number_id = "647015955153740"

# Text, with a reply quote
{:ok, %{"messages" => [%{"id" => wamid}]}} =
  Messages.send_text(client, phone_number_id, "56961567267", "Hola!", reply_to: "wamid.HBg...")

# Business-scoped user IDs work too
Messages.send_text(client, phone_number_id, %{recipient: "US.13491208655302741918"}, "Hola!")

# Media: a URL, an uploaded media ID, or a map
Messages.send_image(client, phone_number_id, "56961567267", "https://example.com/menu.jpg", caption: "Menu")

{:ok, %{"id" => media_id}} = Media.upload_file(client, phone_number_id, "invoice.pdf")
Messages.send_document(client, phone_number_id, "56961567267", media_id, filename: "invoice.pdf")

# Templates
Messages.send_template(client, phone_number_id, "56961567267", "order_update", "es",
  components: [
    TemplateComponents.header_media(:image, "https://example.com/box.jpg"),
    TemplateComponents.body(first_name: "Ana", order: "#1234"),
    TemplateComponents.button_url(0, "1234")
  ]
)

# Interactive messages
Messages.send_buttons(client, phone_number_id, "56961567267", "Confirm your order?", [
  {"yes", "Yes"},
  {"no", "No"}
])

Messages.send_list(client, phone_number_id, "56961567267", "Shipping", "Options", [
  %{title: "Fast", rows: [%{id: "express", title: "Express", description: "1-2 days"}]}
])

# Read receipts with typing indicator
Messages.mark_read(client, phone_number_id, wamid, typing_indicator: true)

# Anything else: send Meta's payload as is
Messages.send(client, phone_number_id, %{to: "56961567267", type: "sticker", sticker: %{id: "123"}})

# Stored history, with Kapso extension fields
Messages.list(client, phone_number_id,
  direction: "inbound",
  limit: 50,
  fields: KapsoEx.WhatsApp.kapso_fields([:media_url, :flow_response])
)

# Template management on the WhatsApp Business Account
Templates.list(client, business_account_id, status: "APPROVED")
```

Other modules: `Conversations` (including thread control on shared numbers), `Contacts`, `Calls`, `Flows`, `PhoneNumbers`, `BusinessProfile`, `BlockUsers`, `Usernames` and `ConversionEvents`.

## Platform

Attributes are maps or keyword lists. When an endpoint expects a root key (`{"customer": {...}}`), the function adds it:

```elixir
alias KapsoEx.Platform.{Broadcasts, Customers, SetupLinks}

{:ok, %{"data" => %{"id" => customer_id}}} =
  Customers.create(client, name: "Acme", external_customer_id: "acme-1")

{:ok, %{"data" => %{"url" => onboarding_url}}} =
  SetupLinks.create(client, customer_id, success_redirect_url: "https://app.example.com/done", language: "es")

{:ok, %{"data" => %{"id" => broadcast_id}}} =
  Broadcasts.create(client, name: "Black Friday", phone_number_id: phone_number_id, whatsapp_template_id: template_id)

Broadcasts.add_recipients(client, broadcast_id, [
  %{phone_number: "+56961567267", components: [TemplateComponents.body(first_name: "Ana")]}
])

Broadcasts.schedule(client, broadcast_id, ~U[2026-11-27 12:00:00Z])
```

Also available: `PhoneNumbers`, `Webhooks`, `Messages`, `Conversations` (with assignments), `Contacts`, `Media` (ingest from URL), `Flows` (versions and data endpoints), `Events`, `Findings`, `DisplayNames`, `InboxEmbeds`, `Notifications`, `Users`, `WebhookDeliveries`, `ApiLogs`, `LogSearch`, `ProviderModels`, `Funding` and `BusinessVerification`.

## Workflows, Functions and Kapso Agent

```elixir
{:ok, %{"data" => %{"id" => execution_id}}} =
  KapsoEx.Workflows.Executions.start(client, workflow_id,
    phone_number: "+56961567267",
    phone_number_id: phone_number_id,
    variables: %{order_id: "ORD-1234"}
  )

KapsoEx.Workflows.Executions.resume(client, execution_id, "yes", kind: "text")

KapsoEx.Functions.invoke(client, function_id, %{order_id: "ORD-1234"})

KapsoEx.Agent.Runs.create(client, mode: "api", input: %{prompt: "Which conversations failed today?"})
```

## Pagination

`KapsoEx.Pagination.stream/2` walks page based (`meta.page`/`total_pages`) and cursor based (`paging.cursors.after`) lists lazily:

```elixir
KapsoEx.Pagination.stream(&KapsoEx.Platform.Customers.list(client, &1), per_page: 100)
|> Enum.to_list()

KapsoEx.Pagination.stream(&KapsoEx.WhatsApp.Messages.list(client, phone_number_id, &1), limit: 100)
|> Stream.filter(&(&1["type"] == "image"))
|> Enum.take(20)
```

## Webhooks

Kapso signs webhooks with HMAC-SHA256 of the raw body (`X-Webhook-Signature`). Keep the raw body with the bundled body reader (requires `:plug`):

```elixir
# endpoint.ex
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  body_reader: {KapsoEx.Webhook.CacheBodyReader, :read_body, []},
  json_decoder: Jason
```

```elixir
# controller
def create(conn, _params) do
  raw_body = KapsoEx.Webhook.CacheBodyReader.raw_body(conn)
  [signature] = get_req_header(conn, "x-webhook-signature")
  [event] = get_req_header(conn, "x-webhook-event")

  case KapsoEx.Webhook.construct_event(raw_body, signature, webhook_secret()) do
    {:ok, body} ->
      # Buffered webhooks arrive as a batch; payloads/1 always returns a list
      for payload <- KapsoEx.Webhook.payloads(body), do: MyApp.Inbox.handle(event, payload)
      send_resp(conn, 200, "ok")

    {:error, _} ->
      send_resp(conn, 401, "invalid signature")
  end
end
```

Use `X-Idempotency-Key` to drop duplicate deliveries. For webhooks sent directly by Meta, use `KapsoEx.Webhook.verify_meta_signature/3` with the `X-Hub-Signature-256` header.

## Endpoints not wrapped yet

```elixir
KapsoEx.request(client, :platform, :get, "/some/new/endpoint", query: [limit: 10])
```

## Testing your application

Route requests to a [`Req.Test`](https://hexdocs.pm/req/Req.Test.html) stub:

```elixir
# config/test.exs
config :kapso_ex, api_key: "test", req_options: [plug: {Req.Test, KapsoEx}]

# test
Req.Test.stub(KapsoEx, fn conn ->
  Req.Test.json(conn, %{"messages" => [%{"id" => "wamid.test"}]})
end)
```

## Development

```sh
mix test
mix format --check-formatted
mix docs
```

`test/kapso_ex/endpoints_test.exs` checks every operation listed in `test/support/openapi_operations.txt` against its function (HTTP method and path). To pick up new endpoints when Kapso updates its specs:

```sh
ruby scripts/openapi_operations.rb > test/support/openapi_operations.txt
mix test test/kapso_ex/endpoints_test.exs
```
