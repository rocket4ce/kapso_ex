defmodule KapsoEx.WhatsApp.MessagesTest do
  use ExUnit.Case, async: true

  import KapsoEx.TestHelpers

  alias KapsoEx.WhatsApp.Messages

  setup do
    capture(%{"messaging_product" => "whatsapp", "messages" => [%{"id" => "wamid.1"}]})
    %{client: client()}
  end

  defp sent_json do
    assert_received {:request,
                     %{method: "POST", path: "/meta/whatsapp/v24.0/123/messages", json: json}}

    json
  end

  test "send_text/5 with reply context and preview", %{client: client} do
    assert {:ok, %{"messages" => [%{"id" => "wamid.1"}]}} =
             Messages.send_text(client, "123", "56961567267", "Hola",
               preview_url: true,
               reply_to: "wamid.0"
             )

    assert sent_json() == %{
             "messaging_product" => "whatsapp",
             "to" => "56961567267",
             "type" => "text",
             "text" => %{"body" => "Hola", "preview_url" => true},
             "context" => %{"message_id" => "wamid.0"}
           }
  end

  test "recipients can be a business-scoped user ID or both identifiers", %{client: client} do
    Messages.send_text(client, "123", %{recipient: "US.134"}, "Hola")
    assert %{"recipient" => "US.134"} = json = sent_json()
    refute Map.has_key?(json, "to")

    Messages.send_text(client, "123", [to: "569", recipient: "US.134"], "Hola")
    assert %{"to" => "569", "recipient" => "US.134"} = sent_json()

    assert_raise ArgumentError, fn -> Messages.send_text(client, "123", %{}, "Hola") end
  end

  test "media accepts links, IDs and maps", %{client: client} do
    Messages.send_image(client, "123", "569", "https://example.com/a.jpg", caption: "Look")

    assert %{
             "type" => "image",
             "image" => %{"link" => "https://example.com/a.jpg", "caption" => "Look"}
           } = sent_json()

    Messages.send_audio(client, "123", "569", "1013859600285441", voice: true)
    assert %{"audio" => %{"id" => "1013859600285441", "voice" => true}} = sent_json()

    Messages.send_document(client, "123", "569", %{id: "9"}, filename: "report.pdf")
    assert %{"document" => %{"id" => "9", "filename" => "report.pdf"}} = sent_json()
  end

  test "send_template/6", %{client: client} do
    components = [%{type: "body", parameters: [%{type: "text", text: "Ana"}]}]

    Messages.send_template(client, "123", "569", "order_update", "es",
      components: components,
      biz_opaque_callback_data: "order-1"
    )

    assert sent_json() == %{
             "messaging_product" => "whatsapp",
             "to" => "569",
             "type" => "template",
             "biz_opaque_callback_data" => "order-1",
             "template" => %{
               "name" => "order_update",
               "language" => %{"code" => "es"},
               "components" => [
                 %{"type" => "body", "parameters" => [%{"type" => "text", "text" => "Ana"}]}
               ]
             }
           }
  end

  test "send_marketing_template/6 uses the marketing endpoint", %{client: client} do
    Messages.send_marketing_template(client, "123", %{recipient: "US.1"}, "promo", "en_US")

    assert_received {:request, %{path: "/meta/whatsapp/v24.0/123/marketing_messages", json: json}}

    assert %{"recipient" => "US.1", "type" => "template", "template" => %{"name" => "promo"}} =
             json
  end

  test "send_buttons/6 builds reply buttons, header and footer", %{client: client} do
    Messages.send_buttons(client, "123", "569", "Confirm?", [{"yes", "Yes"}, {"no", "No"}],
      header: "Order #1",
      footer: "Thanks"
    )

    assert %{
             "type" => "interactive",
             "interactive" => %{
               "type" => "button",
               "header" => %{"type" => "text", "text" => "Order #1"},
               "body" => %{"text" => "Confirm?"},
               "footer" => %{"text" => "Thanks"},
               "action" => %{
                 "buttons" => [
                   %{"type" => "reply", "reply" => %{"id" => "yes", "title" => "Yes"}},
                   %{"type" => "reply", "reply" => %{"id" => "no", "title" => "No"}}
                 ]
               }
             }
           } = sent_json()
  end

  test "send_list/7, send_cta_url/7, send_flow/6 and send_location_request/5", %{client: client} do
    sections = [%{title: "Shipping", rows: [%{id: "express", title: "Express"}]}]
    Messages.send_list(client, "123", "569", "Pick one", "Options", sections)

    assert %{
             "interactive" => %{
               "type" => "list",
               "action" => %{"button" => "Options", "sections" => [_]}
             }
           } =
             sent_json()

    Messages.send_cta_url(client, "123", "569", "See dates", "Open", "https://example.com")

    assert %{
             "interactive" => %{
               "type" => "cta_url",
               "action" => %{
                 "name" => "cta_url",
                 "parameters" => %{"display_text" => "Open", "url" => "https://example.com"}
               }
             }
           } = sent_json()

    Messages.send_flow(client, "123", "569", "Book", %{flow_id: "f1", flow_cta: "Go"})

    assert %{
             "interactive" => %{
               "type" => "flow",
               "action" => %{
                 "name" => "flow",
                 "parameters" => %{
                   "flow_id" => "f1",
                   "flow_cta" => "Go",
                   "flow_message_version" => "3"
                 }
               }
             }
           } = sent_json()

    Messages.send_location_request(client, "123", "569", "Where are you?")

    assert %{
             "interactive" => %{
               "type" => "location_request_message",
               "action" => %{"name" => "send_location"}
             }
           } =
             sent_json()
  end

  test "send_reaction/6, send_location/5 and send_contacts/5", %{client: client} do
    Messages.send_reaction(client, "123", "569", "wamid.0", "👍")

    assert %{"type" => "reaction", "reaction" => %{"message_id" => "wamid.0", "emoji" => "👍"}} =
             sent_json()

    Messages.send_location(client, "123", "569", latitude: -33.44, longitude: -70.66)
    assert %{"location" => %{"latitude" => -33.44, "longitude" => -70.66}} = sent_json()

    Messages.send_contacts(client, "123", "569", [%{name: %{formatted_name: "Ada"}}])
    assert %{"contacts" => [%{"name" => %{"formatted_name" => "Ada"}}]} = sent_json()
  end

  test "mark_read/4 with typing indicator", %{client: client} do
    Messages.mark_read(client, "123", "wamid.0", typing_indicator: true)

    assert sent_json() == %{
             "messaging_product" => "whatsapp",
             "status" => "read",
             "message_id" => "wamid.0",
             "typing_indicator" => %{"type" => "text"}
           }
  end

  test "send/4 keeps messaging_product and sets the take control header", %{client: client} do
    payload = %{"messaging_product" => "whatsapp", "to" => "569", "type" => "text"}
    Messages.send(client, "123", payload, take_control: true)

    assert_received {:request, %{json: json, headers: headers}}
    assert json == %{"messaging_product" => "whatsapp", "to" => "569", "type" => "text"}
    assert headers["x-kapso-take-control"] == "true"
  end

  test "list/3 passes Kapso fields", %{client: client} do
    Messages.list(client, "123", fields: KapsoEx.WhatsApp.kapso_fields([:media_url]), limit: 5)

    assert_received {:request,
                     %{method: "GET", query: %{"fields" => "kapso(media_url)", "limit" => "5"}}}
  end
end
