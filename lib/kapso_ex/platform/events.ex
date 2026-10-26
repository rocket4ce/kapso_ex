defmodule KapsoEx.Platform.Events do
  @moduledoc """
  [Project events](https://docs.kapso.ai/docs/platform/events): timestamped
  data points you record (for example `order.created`) that can trigger
  workflows, plus the definitions that describe them.

  Event names are lowercase, optionally with dot-separated segments; each
  segment starts with a letter and may contain letters, numbers and
  underscores.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map() | nil} | {:error, KapsoEx.Error.t()}

  @doc """
  Emits an event.

  ## Options

    * `:properties` - map of event properties.
    * `:conversation_id` - link the event to a WhatsApp conversation.
    * `:occurred_at` - `DateTime` or ISO 8601 string; defaults to now.

  ## Examples

      Events.emit(client, "order.created", properties: %{order_id: "1234", total: 59.9})
  """
  @spec emit(Client.t(), String.t(), keyword()) :: result()
  def emit(%Client{} = client, name, opts \\ []) do
    attrs = opts |> Keyword.take([:properties, :conversation_id, :occurred_at]) |> Map.new()
    Request.post(client, :platform, ["events"], json: Map.put(attrs, :name, name))
  end

  @doc """
  Lists events, newest first.

  Params: `name`, `conversation_id`, `occurred_after`, `occurred_before`,
  `limit`, `before`, `after`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["events"], query: params)
  end

  @doc "Lists event definitions. Params: `include_archived`."
  @spec list_definitions(Client.t(), map() | keyword()) :: result()
  def list_definitions(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["event-definitions"], query: params)
  end

  @doc """
  Creates an event definition, or updates (and unarchives) the one with the
  same name. Attributes: `name` (required), `description`,
  `property_schema`.
  """
  @spec create_definition(Client.t(), map() | keyword()) :: result()
  def create_definition(%Client{} = client, attrs) do
    Request.post(client, :platform, ["event-definitions"], json: attrs)
  end

  @doc "Gets an event definition."
  @spec get_definition(Client.t(), String.t()) :: result()
  def get_definition(%Client{} = client, id) do
    Request.get(client, :platform, ["event-definitions", id])
  end

  @doc """
  Updates an event definition: `name`, `description`, `property_schema`,
  or `archived` (to hide it while keeping its events).
  """
  @spec update_definition(Client.t(), String.t(), map() | keyword()) :: result()
  def update_definition(%Client{} = client, id, attrs) do
    Request.patch(client, :platform, ["event-definitions", id], json: attrs)
  end

  @doc """
  Permanently deletes an event definition **and all its recorded events**.
  Deletion runs in the background (`202 Accepted`). To keep history,
  archive it with `update_definition/3` instead.
  """
  @spec delete_definition(Client.t(), String.t()) :: result()
  def delete_definition(%Client{} = client, id) do
    Request.delete(client, :platform, ["event-definitions", id])
  end
end
