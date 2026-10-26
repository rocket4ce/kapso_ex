defmodule KapsoEx.WhatsApp.TemplateComponentsTest do
  use ExUnit.Case, async: true

  alias KapsoEx.WhatsApp.TemplateComponents, as: C

  doctest KapsoEx.WhatsApp

  test "body/1 with positional and named parameters" do
    assert C.body(["Ana", "#1"]) == %{
             type: "body",
             parameters: [%{type: "text", text: "Ana"}, %{type: "text", text: "#1"}]
           }

    assert C.body(first_name: "Ana") == %{
             type: "body",
             parameters: [%{type: "text", text: "Ana", parameter_name: "first_name"}]
           }

    currency = %{
      type: "currency",
      currency: %{fallback_value: "$10", code: "USD", amount_1000: 10_000}
    }

    assert C.body([currency]) == %{type: "body", parameters: [currency]}
  end

  test "headers" do
    assert C.header_text("Sale") == %{type: "header", parameters: [%{type: "text", text: "Sale"}]}

    assert C.header_text(:sale_name, "Sale") == %{
             type: "header",
             parameters: [%{type: "text", text: "Sale", parameter_name: "sale_name"}]
           }

    assert C.header_media(:image, "https://example.com/a.jpg") == %{
             type: "header",
             parameters: [%{type: :image, image: %{link: "https://example.com/a.jpg"}}]
           }

    assert C.header_media(:document, "4490") == %{
             type: "header",
             parameters: [%{type: :document, document: %{id: "4490"}}]
           }
  end

  test "buttons" do
    assert C.button_url(0, "summer") == %{
             type: "button",
             sub_type: "url",
             index: "0",
             parameters: [%{type: "text", text: "summer"}]
           }

    assert C.button_quick_reply(1, "stop") == %{
             type: "button",
             sub_type: "quick_reply",
             index: "1",
             parameters: [%{type: "payload", payload: "stop"}]
           }

    assert %{sub_type: "copy_code", parameters: [%{type: "coupon_code", coupon_code: "25OFF"}]} =
             C.button_copy_code(0, "25OFF")

    assert %{sub_type: "flow", parameters: [%{type: "action", action: %{flow_token: "t"}}]} =
             C.button_flow(0, %{flow_token: "t"})
  end

  test "authentication/1 puts the code in the body and the button" do
    assert [
             %{type: "body", parameters: [%{text: "482913"}]},
             %{type: "button", parameters: [%{text: "482913"}]}
           ] =
             C.authentication("482913")
  end
end
