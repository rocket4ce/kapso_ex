defmodule KapsoEx.RequestTest do
  use ExUnit.Case, async: true

  import KapsoEx.TestHelpers

  alias KapsoEx.Error

  describe "auth and headers" do
    test "sends the API key and a user agent" do
      capture()
      {:ok, _} = KapsoEx.Platform.Customers.list(client())

      assert_received {:request, %{headers: headers}}
      assert headers["x-api-key"] == "test_key"
      assert headers["user-agent"] =~ ~r/^kapso_ex\//
    end

    test "uses the bearer token for the WhatsApp API when set" do
      capture()
      client = client(access_token: "meta_token")

      {:ok, _} = KapsoEx.WhatsApp.PhoneNumbers.get(client, "123")
      assert_received {:request, %{headers: headers}}
      assert headers["authorization"] == "Bearer meta_token"
      refute Map.has_key?(headers, "x-api-key")

      {:ok, _} = KapsoEx.Platform.Customers.list(client)
      assert_received {:request, %{headers: %{"x-api-key" => "test_key"}}}
    end

    test "raises when the Platform API is called without an API key" do
      client = client(api_key: nil, access_token: "meta_token")

      assert_raise ArgumentError, ~r/platform API requires an :api_key/, fn ->
        KapsoEx.Platform.Customers.list(client)
      end
    end
  end

  describe "query params and paths" do
    test "drops nil params and encodes dates as ISO 8601" do
      capture()

      {:ok, _} =
        KapsoEx.Platform.Customers.list(client(),
          name_contains: nil,
          created_after: ~U[2025-01-02 03:04:05Z],
          per_page: 10
        )

      assert_received {:request, %{query: query}}
      assert query == %{"created_after" => "2025-01-02T03:04:05Z", "per_page" => "10"}
    end

    test "URL-encodes path segments" do
      capture()
      {:ok, _} = KapsoEx.Platform.Contacts.get(client(), "+56 9/1")

      assert_received {:request, %{path: "/platform/v1/whatsapp/contacts/%2B56%209%2F1"}}
    end
  end

  describe "responses" do
    test "returns the decoded body as is" do
      capture(%{"data" => [%{"id" => "c1"}], "meta" => %{"page" => 1}})

      assert {:ok, %{"data" => [%{"id" => "c1"}], "meta" => %{"page" => 1}}} =
               KapsoEx.Platform.Customers.list(client())
    end

    test "returns nil for empty bodies" do
      Req.Test.stub(KapsoEx, &Plug.Conn.send_resp(&1, 204, ""))
      assert {:ok, nil} = KapsoEx.Platform.Customers.delete(client(), "c1")
    end

    test "maps Kapso errors" do
      capture(%{"error" => "Customer not found"}, 404)

      assert {:error, %Error{status: 404, message: "Customer not found", code: nil} = error} =
               KapsoEx.Platform.Customers.get(client(), "missing")

      assert Exception.message(error) == "(HTTP 404) Customer not found"
    end

    test "maps Meta style errors" do
      capture(
        %{
          "error" => %{
            "message" => "Re-engagement message",
            "type" => "OAuthException",
            "code" => 131_047
          }
        },
        400
      )

      assert {:error, %Error{status: 400, message: "Re-engagement message", code: 131_047}} =
               KapsoEx.WhatsApp.Messages.send_text(client(), "123", "56961567267", "hi")
    end

    test "exposes Retry-After on rate limits" do
      Req.Test.stub(KapsoEx, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("retry-after", "60")
        |> Plug.Conn.put_status(429)
        |> Req.Test.json(%{"error" => "Rate limit exceeded", "message" => "Try again later"})
      end)

      assert {:error, %Error{status: 429, message: "Rate limit exceeded", retry_after: 60}} =
               KapsoEx.Platform.Customers.list(client())
    end

    test "wraps transport errors" do
      Req.Test.stub(KapsoEx, &Req.Test.transport_error(&1, :econnrefused))

      assert {:error,
              %Error{status: nil, reason: %Req.TransportError{reason: :econnrefused}} = error} =
               KapsoEx.Platform.Customers.list(client())

      assert Exception.message(error) =~ "connection refused"
    end
  end

  describe "KapsoEx.request/5" do
    test "calls arbitrary endpoints" do
      capture(%{"ok" => true})

      assert {:ok, %{"ok" => true}} =
               KapsoEx.request(client(), :platform, :post, ["custom", "path"],
                 query: [a: 1],
                 json: %{b: 2},
                 headers: [{"x-extra", "1"}]
               )

      assert_received {:request, request}
      assert request.method == "POST"
      assert request.path == "/platform/v1/custom/path"
      assert request.query == %{"a" => "1"}
      assert request.json == %{"b" => 2}
      assert request.headers["x-extra"] == "1"
    end
  end
end
