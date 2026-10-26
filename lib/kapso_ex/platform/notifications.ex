defmodule KapsoEx.Platform.Notifications do
  @moduledoc """
  Route Kapso notification events to team destinations (shared email
  addresses or Slack channels).
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map() | nil} | {:error, KapsoEx.Error.t()}

  @doc "Lists the event types you can route. Use their `key` in `upsert_route/3`."
  @spec list_event_types(Client.t()) :: result()
  def list_event_types(%Client{} = client) do
    Request.get(client, :platform, ["notifications", "events"])
  end

  @doc "Lists shared email and Slack channel destinations, including pending ones."
  @spec list_destinations(Client.t()) :: result()
  def list_destinations(%Client{} = client) do
    Request.get(client, :platform, ["notifications", "destinations"])
  end

  @doc """
  Creates a shared email destination and sends a verification email
  (valid for 7 days). It receives notifications once confirmed.

  ## Options

    * `:label` - display name of the destination.
  """
  @spec create_email_destination(Client.t(), String.t(), keyword()) :: result()
  def create_email_destination(%Client{} = client, address, opts \\ []) do
    attrs =
      opts
      |> Keyword.take([:label])
      |> Map.new()
      |> Map.merge(%{kind: "shared_email", address: address})

    Request.post(client, :platform, ["notifications", "destinations"], json: attrs)
  end

  @doc "Removes a destination, its routes and pending deliveries."
  @spec delete_destination(Client.t(), String.t()) :: result()
  def delete_destination(%Client{} = client, destination_id) do
    Request.delete(client, :platform, ["notifications", "destinations", destination_id])
  end

  @doc "Lists routes (event type to destination), oldest first."
  @spec list_routes(Client.t()) :: result()
  def list_routes(%Client{} = client) do
    Request.get(client, :platform, ["notifications", "routes"])
  end

  @doc "Routes `event_key` to a destination. Returns the existing route when it already exists."
  @spec upsert_route(Client.t(), String.t(), String.t()) :: result()
  def upsert_route(%Client{} = client, destination_id, event_key) do
    Request.put(client, :platform, ["notifications", "routes"],
      json: %{destination_id: destination_id, event_key: event_key}
    )
  end

  @doc "Deletes a route and cancels its pending deliveries."
  @spec delete_route(Client.t(), String.t()) :: result()
  def delete_route(%Client{} = client, route_id) do
    Request.delete(client, :platform, ["notifications", "routes", route_id])
  end
end
