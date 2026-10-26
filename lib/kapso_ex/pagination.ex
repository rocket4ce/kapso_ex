defmodule KapsoEx.Pagination do
  @moduledoc """
  Lazily walks every page of a list endpoint.

  Kapso list endpoints paginate in one of two ways, and `stream/2` handles
  both by looking at the response:

    * **Page based** - the body has `meta` with `page` and `total_pages`
      (or `has_next`). The stream requests `page + 1` until the last page.
    * **Cursor based** - the body has `paging.cursors.after`. The stream
      passes it as `after` until there is no next page.

  ## Example

      KapsoEx.Pagination.stream(&KapsoEx.Platform.Customers.list(client, &1), per_page: 100)
      |> Stream.filter(&(&1["external_customer_id"] != nil))
      |> Enum.to_list()

      KapsoEx.Pagination.stream(
        &KapsoEx.WhatsApp.Messages.list(client, "647015955153740", &1),
        limit: 100, direction: "inbound"
      )
      |> Enum.take(500)

  Requests are made only as items are consumed. When a page request fails
  the stream raises the `KapsoEx.Error`.
  """

  @doc """
  Returns a stream of the items in `data` across all pages.

  `fun` receives the params for each page (a map with atom keys, starting
  from `params`) and must return the result of a list function.
  """
  @spec stream((map() -> {:ok, map()} | {:error, KapsoEx.Error.t()}), map() | keyword()) ::
          Enumerable.t()
  def stream(fun, params \\ []) when is_function(fun, 1) do
    Stream.resource(
      fn -> Map.new(params) end,
      fn
        :done ->
          {:halt, :done}

        params ->
          case fun.(params) do
            {:ok, %{"data" => data} = body} when is_list(data) ->
              {data, next_params(body, data, params)}

            {:ok, body} ->
              raise ArgumentError,
                    "expected a list response with a \"data\" list, got: #{inspect(body)}"

            {:error, error} ->
              raise error
          end
      end,
      fn _ -> :ok end
    )
  end

  defp next_params(_body, [], _params), do: :done

  defp next_params(body, _data, params) do
    cond do
      cursor = next_cursor(body["paging"], params) ->
        params |> Map.delete(:before) |> Map.put(:after, cursor)

      page = next_page(body["meta"]) ->
        Map.put(params, :page, page)

      true ->
        :done
    end
  end

  defp next_cursor(%{"cursors" => %{"after" => cursor}} = paging, params)
       when is_binary(cursor) and cursor != "" do
    has_next? = not Map.has_key?(paging, "next") or not is_nil(paging["next"])
    if has_next? and cursor != params[:after], do: cursor
  end

  defp next_cursor(_paging, _params), do: nil

  defp next_page(%{"page" => page, "total_pages" => total})
       when is_integer(page) and is_integer(total) and page < total,
       do: page + 1

  defp next_page(%{"page" => page, "has_next" => true}) when is_integer(page), do: page + 1
  defp next_page(_meta), do: nil
end
