defmodule KapsoEx.Platform.Messages do
  @moduledoc """
  Query WhatsApp messages across all conversations and numbers of the
  project. To send messages use `KapsoEx.WhatsApp.Messages`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists messages, newest first, with cursor pagination.

  Params: `phone_number_id`, `conversation_id`, `phone_number`,
  `business_scoped_user_id`, `direction`, `status`, `message_type`,
  `has_media`, `limit`, `before`, `after`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "messages"], query: params)
  end

  @doc "Gets a message by its WhatsApp message ID (WAMID)."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, message_id) do
    Request.get(client, :platform, ["whatsapp", "messages", message_id])
  end
end
