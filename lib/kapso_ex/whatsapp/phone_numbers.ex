defmodule KapsoEx.WhatsApp.PhoneNumbers do
  @moduledoc """
  Phone number details and settings, as returned by Meta.

  To connect, list or delete numbers in your Kapso project, use
  `KapsoEx.Platform.PhoneNumbers`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc "Lists the phone numbers of a WhatsApp Business Account. Params: `fields`."
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, business_account_id, params \\ []) do
    Request.get(client, :whatsapp, [business_account_id, "phone_numbers"], query: params)
  end

  @doc "Gets phone number details (quality rating, name status, throughput, ...). Params: `fields`."
  @spec get(Client.t(), String.t(), map() | keyword()) :: result()
  def get(%Client{} = client, phone_number_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id], query: params)
  end

  @doc """
  Updates phone number settings, most commonly the two-step verification PIN:

      PhoneNumbers.update(client, phone_number_id, %{pin: "123456"})
  """
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, phone_number_id, attrs) do
    Request.post(client, :whatsapp, [phone_number_id], json: attrs)
  end
end
