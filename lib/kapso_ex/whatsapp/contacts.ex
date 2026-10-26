defmodule KapsoEx.WhatsApp.Contacts do
  @moduledoc """
  Contacts stored by Kapso for a phone number.

  To create, update or erase contacts use `KapsoEx.Platform.Contacts`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists contacts. Params: `wa_id`, `customer_id`, `has_customer`, `limit`,
  `before`, `after`, `fields`.
  """
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, phone_number_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "contacts"], query: params)
  end

  @doc "Gets a contact by WhatsApp ID (phone number). Params: `fields`."
  @spec get(Client.t(), String.t(), String.t(), map() | keyword()) :: result()
  def get(%Client{} = client, phone_number_id, wa_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "contacts", wa_id], query: params)
  end
end
