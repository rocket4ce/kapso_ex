defmodule KapsoEx.ClientTest do
  # Not async: some tests change the :kapso_ex application environment.
  use ExUnit.Case

  test "new/1 builds a client with defaults" do
    client = KapsoEx.new(api_key: "key")

    assert client.api_key == "key"
    assert client.whatsapp_base_url == "https://api.kapso.ai/meta/whatsapp/v24.0"
    assert client.platform_base_url == "https://api.kapso.ai/platform/v1"
    assert client.req_options == []
  end

  test "new/1 requires an api key or an access token" do
    assert_raise ArgumentError, ~r/requires an :api_key/, fn -> KapsoEx.new() end
    assert %KapsoEx.Client{access_token: "token"} = KapsoEx.new(access_token: "token")
  end

  test "new/1 rejects unknown options" do
    assert_raise ArgumentError, fn -> KapsoEx.new(api_key: "key", apikey: "typo") end
  end

  test "new/1 falls back to the application environment" do
    Application.put_env(:kapso_ex, :api_key, "from_env")
    Application.put_env(:kapso_ex, :platform_base_url, "https://example.test/v1")

    on_exit(fn ->
      Application.delete_env(:kapso_ex, :api_key)
      Application.delete_env(:kapso_ex, :platform_base_url)
    end)

    assert %{api_key: "from_env", platform_base_url: "https://example.test/v1"} = KapsoEx.new()
    assert %{api_key: "explicit"} = KapsoEx.new(api_key: "explicit")
  end

  test "inspect does not leak credentials" do
    inspected = inspect(KapsoEx.new(api_key: "secret_key", access_token: "secret_token"))

    refute inspected =~ "secret_key"
    refute inspected =~ "secret_token"
  end
end
