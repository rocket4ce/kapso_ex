defmodule KapsoEx.Platform.Contacts do
  @moduledoc """
  WhatsApp contacts of the project.

  `identifier` may be the contact's UUID, phone number (WhatsApp ID) or
  business-scoped user ID.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map() | nil} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists contacts.

  Params: `customer_id`, `customer_external_id`, `has_customer`,
  `profile_name_contains`, `wa_id_contains`, `business_scoped_user_id`,
  `created_after`, `created_before`, and either `page`/`per_page` or
  `limit`/`before`/`after`. Use cursors for deep pagination.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "contacts"], query: params)
  end

  @doc """
  Creates a contact. Attributes: `wa_id` (required), `profile_name`,
  `display_name`, `customer_id`, `metadata`.
  """
  @spec create(Client.t(), map() | keyword()) :: result()
  def create(%Client{} = client, attrs) do
    Request.post(client, :platform, ["whatsapp", "contacts"], json: Request.wrap(attrs, :contact))
  end

  @doc "Gets a contact."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, identifier) do
    Request.get(client, :platform, ["whatsapp", "contacts", identifier])
  end

  @doc "Updates a contact's profile or metadata. Attributes as in `create/2`."
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, identifier, attrs) do
    Request.patch(client, :platform, ["whatsapp", "contacts", identifier],
      json: Request.wrap(attrs, :contact)
    )
  end

  @doc """
  Permanently erases a contact and all its data (conversations, messages,
  media). This cannot be undone.
  """
  @spec erase(Client.t(), String.t()) :: result()
  def erase(%Client{} = client, identifier) do
    Request.delete(client, :platform, ["whatsapp", "contacts", identifier])
  end

  @doc """
  Lists the contact's marketing preference on each of your numbers. An
  empty list means the contact never opted out.
  """
  @spec list_marketing_preferences(Client.t(), String.t()) :: result()
  def list_marketing_preferences(%Client{} = client, identifier) do
    Request.get(client, :platform, ["whatsapp", "contacts", identifier, "marketing_preferences"])
  end

  @doc "Gets the contact's marketing preference on one number."
  @spec get_marketing_preference(Client.t(), String.t(), String.t()) :: result()
  def get_marketing_preference(%Client{} = client, identifier, phone_number_id) do
    Request.get(client, :platform, [
      "whatsapp",
      "contacts",
      identifier,
      "marketing_preferences",
      phone_number_id
    ])
  end
end
