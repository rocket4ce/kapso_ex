defmodule KapsoEx.Platform.PhoneNumbers do
  @moduledoc """
  WhatsApp numbers connected to your Kapso project.

  For Meta's view of a number (quality rating, PIN, ...) see
  `KapsoEx.WhatsApp.PhoneNumbers`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map() | nil} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists phone numbers, most recent first.

  Params: `phone_number_id`, `business_account_id`, `customer_id`,
  `messaging_enabled`, `name_contains`, `created_after`, `created_before`,
  `page`, `per_page`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "phone_numbers"], query: params)
  end

  @doc """
  Connects a number you configured in Meta to a customer, using Meta
  credentials.

  Attributes: `name`, `phone_number_id`, `business_account_id`,
  `access_token` (required), `kind` (`"production"` or `"sandbox"`),
  `webhook_verify_token`, `webhook_destination_url`,
  `inbound_processing_enabled`, `calls_enabled`.
  """
  @spec connect(Client.t(), String.t(), map() | keyword()) :: result()
  def connect(%Client{} = client, customer_id, attrs) do
    Request.post(client, :platform, ["customers", customer_id, "whatsapp", "phone_numbers"],
      json: Request.wrap(attrs, :whatsapp_phone_number)
    )
  end

  @doc "Gets a phone number."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, phone_number_id) do
    Request.get(client, :platform, ["whatsapp", "phone_numbers", phone_number_id])
  end

  @doc "Updates a phone number. Attributes as in `connect/3`."
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, phone_number_id, attrs) do
    Request.patch(client, :platform, ["whatsapp", "phone_numbers", phone_number_id],
      json: Request.wrap(attrs, :whatsapp_phone_number)
    )
  end

  @doc "Removes a phone number from the project."
  @spec delete(Client.t(), String.t()) :: result()
  def delete(%Client{} = client, phone_number_id) do
    Request.delete(client, :platform, ["whatsapp", "phone_numbers", phone_number_id])
  end

  @doc """
  Checks the number's health through Meta's APIs and Kapso services.
  Returns `%{"status" => "healthy" | "degraded" | "unhealthy" | "error", "checks" => ...}`.
  """
  @spec health(Client.t(), String.t()) :: result()
  def health(%Client{} = client, phone_number_id) do
    Request.get(client, :platform, ["whatsapp", "phone_numbers", phone_number_id, "health"])
  end
end
