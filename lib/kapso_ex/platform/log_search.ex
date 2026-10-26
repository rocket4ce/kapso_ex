defmodule KapsoEx.Platform.LogSearch do
  @moduledoc """
  Search the same log events shown in the Kapso logs UI: API logs,
  WhatsApp webhook events, flow events and webhook deliveries.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Searches log events.

  Params: `query`, `period` (`"24h"`, `"7d"`, `"context"`), `source`,
  `problems_only`, `errors_only`, `limit`, `cursor`, `around`,
  `highlight_event_id`, `highlight_resource_id`.
  """
  @spec search(Client.t(), map() | keyword()) :: result()
  def search(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["log_search"], query: params)
  end

  @doc """
  Searches log events with structured `filters`, plus the params of
  `search/2` in the body. See `catalog/1` for the supported filter keys.
  """
  @spec search_with_filters(Client.t(), map() | keyword()) :: result()
  def search_with_filters(%Client{} = client, attrs) do
    Request.post(client, :platform, ["log_search"], json: attrs)
  end

  @doc "Returns the log sources, supported filter keys and detail fields."
  @spec catalog(Client.t()) :: result()
  def catalog(%Client{} = client) do
    Request.get(client, :platform, ["log_search", "catalog"])
  end
end
