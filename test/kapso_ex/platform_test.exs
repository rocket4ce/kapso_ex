defmodule KapsoEx.PlatformTest do
  use ExUnit.Case, async: true

  import KapsoEx.TestHelpers

  alias KapsoEx.{Agent, Functions, Platform, Workflows}

  setup do
    capture(%{"data" => %{}})
    %{client: client()}
  end

  defp sent_json do
    assert_received {:request, %{json: json}}
    json
  end

  test "wraps attributes in the root key the endpoint expects", %{client: client} do
    Platform.Customers.create(client, name: "Acme", external_customer_id: "acme-1")
    assert sent_json() == %{"customer" => %{"name" => "Acme", "external_customer_id" => "acme-1"}}

    Platform.SetupLinks.create(client, "c1")
    assert sent_json() == %{"setup_link" => %{}}

    Platform.Webhooks.create_for_phone_number(client, "p1",
      url: "https://x",
      events: ["whatsapp.message.received"]
    )

    assert sent_json() == %{
             "whatsapp_webhook" => %{
               "url" => "https://x",
               "events" => ["whatsapp.message.received"]
             }
           }

    Platform.PhoneNumbers.connect(client, "c1", %{name: "Main", phone_number_id: "1"})

    assert sent_json() == %{
             "whatsapp_phone_number" => %{"name" => "Main", "phone_number_id" => "1"}
           }

    Platform.Broadcasts.add_recipients(client, "b1", [%{phone_number: "+1"}])

    assert sent_json() == %{
             "whatsapp_broadcast" => %{"recipients" => [%{"phone_number" => "+1"}]}
           }

    Platform.Broadcasts.update_status(client, "b1", "stopped")
    assert sent_json() == %{"whatsapp_broadcast" => %{"status" => "stopped"}}

    Platform.Conversations.update_status(client, "conv", "ended")
    assert sent_json() == %{"whatsapp_conversation" => %{"status" => "ended"}}

    Platform.Conversations.create_assignment(client, "conv", user_id: "u1")
    assert sent_json() == %{"assignment" => %{"user_id" => "u1"}}

    Platform.DisplayNames.create(client, "p1", "Acme Store")
    assert sent_json() == %{"display_name_request" => %{"new_display_name" => "Acme Store"}}

    Platform.Contacts.update(client, "+569", metadata: %{tier: "gold"})
    assert sent_json() == %{"contact" => %{"metadata" => %{"tier" => "gold"}}}

    Platform.InboxEmbeds.create(client, scope_type: "project")
    assert sent_json() == %{"inbox_embed" => %{"scope_type" => "project"}}

    Workflows.create(client, name: "Support")
    assert sent_json() == %{"workflow" => %{"name" => "Support"}}

    Workflows.Executions.start(client, "w1", phone_number: "+569", variables: %{a: 1})

    assert sent_json() == %{
             "workflow_execution" => %{"phone_number" => "+569", "variables" => %{"a" => 1}}
           }

    Workflows.Triggers.update(client, "t1", active: false)
    assert sent_json() == %{"trigger" => %{"active" => false}}

    Functions.create(client, name: "f", code: "x", function_type: "cloudflare_worker")

    assert sent_json() == %{
             "function" => %{"name" => "f", "code" => "x", "function_type" => "cloudflare_worker"}
           }

    Functions.create_secret(client, "f1", "TOKEN", "value")
    assert sent_json() == %{"secret" => %{"name" => "TOKEN", "value" => "value"}}
  end

  test "endpoints without a root key get the attributes as is", %{client: client} do
    Platform.Events.emit(client, "order.created",
      properties: %{total: 10},
      conversation_id: "conv"
    )

    assert sent_json() == %{
             "name" => "order.created",
             "properties" => %{"total" => 10},
             "conversation_id" => "conv"
           }

    Platform.Broadcasts.schedule(client, "b1", ~U[2030-01-01 10:00:00Z])
    assert sent_json() == %{"scheduled_at" => "2030-01-01T10:00:00Z"}

    Platform.Findings.dismiss(client, "f1", "expected_behavior", "Seasonal")
    assert sent_json() == %{"reason" => "expected_behavior", "note" => "Seasonal"}

    Platform.Notifications.create_email_destination(client, "ops@example.com", label: "Ops")

    assert sent_json() == %{
             "kind" => "shared_email",
             "address" => "ops@example.com",
             "label" => "Ops"
           }

    Platform.Media.upload(client, "p1", "https://example.com/menu.pdf", delivery: "meta_media")

    assert sent_json() == %{
             "media_ingest" => %{
               "phone_number_id" => "p1",
               "source" => "https://example.com/menu.pdf",
               "delivery" => "meta_media"
             }
           }

    Workflows.Executions.resume(client, "e1", "yes", kind: "text", variables: %{ok: true})

    assert sent_json() == %{
             "message" => %{"kind" => "text", "data" => "yes"},
             "variables" => %{"ok" => true}
           }

    Workflows.Triggers.replace(client, "w1", [%{trigger_type: "api_call"}])
    assert sent_json() == %{"triggers" => [%{"trigger_type" => "api_call"}]}

    Agent.Runs.create(client, mode: "api", input: %{prompt: "hi"})
    assert sent_json() == %{"mode" => "api", "input" => %{"prompt" => "hi"}}
  end

  test "funding usage sends the time range as query params", %{client: client} do
    Platform.Funding.get_account_usage(
      client,
      "waba",
      ~U[2030-01-01 00:00:00Z],
      "2030-02-01T00:00:00Z"
    )

    assert_received {:request, %{query: query}}

    assert query == %{
             "start_time" => "2030-01-01T00:00:00Z",
             "end_time" => "2030-02-01T00:00:00Z"
           }
  end

  test "idempotent endpoints send the Idempotency-Key header", %{client: client} do
    Platform.Funding.revoke_portfolio_funding(client, "portfolio", "revoke-1")
    assert_received {:request, %{headers: %{"idempotency-key" => "revoke-1"}}}

    Platform.BusinessVerification.create_submission(
      client,
      "portfolio",
      [%{source_url: "https://x/a.pdf"}],
      "bv-1"
    )

    assert_received {:request, %{headers: %{"idempotency-key" => "bv-1"}, json: json}}
    assert json == %{"documents" => [%{"source_url" => "https://x/a.pdf"}]}
  end

  test "business verification uploads files as multipart", %{client: client} do
    documents = [
      %{
        file: {"%PDF-1", filename: "certificate.pdf", content_type: "application/pdf"},
        roles: ["legal_name"]
      },
      %{source_url: "https://x/statement.pdf", roles: ["address", "phone"]}
    ]

    Platform.BusinessVerification.create_submission(client, "portfolio", documents, "bv-2")

    assert_received {:request, %{headers: headers, body: body}}
    assert headers["content-type"] =~ "multipart/form-data"

    names = Regex.scan(~r/\bname="([^"]+)"/, body, capture: :all_but_first) |> List.flatten()

    assert names == [
             "documents[][file]",
             "documents[][roles][]",
             "documents[][source_url]",
             "documents[][roles][]",
             "documents[][roles][]"
           ]

    assert body =~ ~s(filename="certificate.pdf")
  end
end
