defmodule KapsoEx.PaginationTest do
  use ExUnit.Case, async: true

  import KapsoEx.TestHelpers

  alias KapsoEx.Pagination

  defp params(conn), do: URI.decode_query(conn.query_string)

  test "walks page based lists until the last page" do
    test_pid = self()

    Req.Test.stub(KapsoEx, fn conn ->
      page = String.to_integer(params(conn)["page"] || "1")
      send(test_pid, {:page, page, params(conn)["per_page"]})

      Req.Test.json(conn, %{
        "data" => [%{"id" => "c#{page}a"}, %{"id" => "c#{page}b"}],
        "meta" => %{"page" => page, "per_page" => 2, "total_pages" => 3, "total_count" => 6}
      })
    end)

    client = client()
    stream = Pagination.stream(&KapsoEx.Platform.Customers.list(client, &1), per_page: 2)

    assert Enum.map(stream, & &1["id"]) == ~w(c1a c1b c2a c2b c3a c3b)
    assert_received {:page, 1, "2"}
    assert_received {:page, 2, "2"}
    assert_received {:page, 3, "2"}
  end

  test "walks cursor based lists until there is no next page" do
    pages = %{
      nil =>
        {[%{"id" => "m1"}, %{"id" => "m2"}],
         %{"cursors" => %{"after" => "cur1"}, "next" => "https://next"}},
      "cur1" => {[%{"id" => "m3"}], %{"cursors" => %{"after" => "cur2"}, "next" => nil}}
    }

    Req.Test.stub(KapsoEx, fn conn ->
      {data, paging} = Map.fetch!(pages, params(conn)["after"])
      Req.Test.json(conn, %{"data" => data, "paging" => paging})
    end)

    client = client()
    stream = Pagination.stream(&KapsoEx.Platform.Messages.list(client, &1), limit: 2)

    assert Enum.map(stream, & &1["id"]) == ~w(m1 m2 m3)
  end

  test "stops on Meta style cursors when a page is empty" do
    Req.Test.stub(KapsoEx, fn conn ->
      data = if params(conn)["after"], do: [], else: [%{"id" => "m1"}]

      Req.Test.json(conn, %{
        "data" => data,
        "paging" => %{"cursors" => %{"before" => "b", "after" => "a"}}
      })
    end)

    client = client()
    stream = Pagination.stream(&KapsoEx.WhatsApp.Messages.list(client, "123", &1))

    assert Enum.to_list(stream) == [%{"id" => "m1"}]
  end

  test "is lazy" do
    test_pid = self()

    Req.Test.stub(KapsoEx, fn conn ->
      send(test_pid, :requested)
      page = String.to_integer(params(conn)["page"] || "1")

      Req.Test.json(conn, %{
        "data" => [%{"page" => page}],
        "meta" => %{"page" => page, "total_pages" => 100}
      })
    end)

    client = client()

    assert [%{"page" => 1}, %{"page" => 2}] =
             Pagination.stream(&KapsoEx.Platform.Users.list(client, &1)) |> Enum.take(2)

    assert_received :requested
    assert_received :requested
    refute_received :requested
  end

  test "raises the error of a failed page" do
    capture(%{"error" => "Invalid API key"}, 401)
    client = client()

    assert_raise KapsoEx.Error, "(HTTP 401) Invalid API key", fn ->
      Pagination.stream(&KapsoEx.Platform.Customers.list(client, &1)) |> Enum.to_list()
    end
  end
end
