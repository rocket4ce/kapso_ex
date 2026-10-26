defmodule KapsoEx.WebhookTest do
  use ExUnit.Case, async: true

  alias KapsoEx.Webhook

  doctest Webhook

  @secret "whsec_test"
  @payload ~s({"event":"whatsapp.message.received","message":{"id":"wamid.1"}})

  defp sign(payload, secret),
    do: :crypto.mac(:hmac, :sha256, secret, payload) |> Base.encode16(case: :lower)

  describe "verify_signature/3" do
    test "accepts a valid signature, in any case" do
      signature = sign(@payload, @secret)

      assert Webhook.verify_signature(@payload, signature, @secret)
      assert Webhook.verify_signature(@payload, String.upcase(signature), @secret)
    end

    test "rejects tampered bodies, wrong secrets and malformed signatures" do
      signature = sign(@payload, @secret)

      refute Webhook.verify_signature(@payload <> " ", signature, @secret)
      refute Webhook.verify_signature(@payload, signature, "other")
      refute Webhook.verify_signature(@payload, "abc", @secret)
      refute Webhook.verify_signature(@payload, nil, @secret)
    end
  end

  test "verify_meta_signature/3 expects the sha256= prefix" do
    signature = sign(@payload, "app_secret")

    assert Webhook.verify_meta_signature(@payload, "sha256=" <> signature, "app_secret")
    refute Webhook.verify_meta_signature(@payload, signature, "app_secret")
    refute Webhook.verify_meta_signature(@payload, nil, "app_secret")
  end

  test "construct_event/3 verifies and decodes" do
    assert {:ok, %{"event" => "whatsapp.message.received"}} =
             Webhook.construct_event(@payload, sign(@payload, @secret), @secret)

    assert {:error, :invalid_signature} = Webhook.construct_event(@payload, "bad", @secret)

    assert {:error, %Jason.DecodeError{}} =
             Webhook.construct_event("nope", sign("nope", @secret), @secret)
  end

  test "CacheBodyReader keeps the raw body for verification" do
    conn =
      Plug.Test.conn(:post, "/webhooks", @payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Parsers.call(
        Plug.Parsers.init(
          parsers: [:json],
          json_decoder: Jason,
          body_reader: {KapsoEx.Webhook.CacheBodyReader, :read_body, []}
        )
      )

    assert conn.body_params["message"]["id"] == "wamid.1"
    assert KapsoEx.Webhook.CacheBodyReader.raw_body(conn) == @payload

    assert Webhook.verify_signature(
             KapsoEx.Webhook.CacheBodyReader.raw_body(conn),
             sign(@payload, @secret),
             @secret
           )
  end
end
