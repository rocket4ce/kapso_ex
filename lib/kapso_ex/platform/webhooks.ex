defmodule KapsoEx.Platform.Webhooks do
  @moduledoc """
  Webhook subscriptions.

    * **Project webhooks** (`list/2`, `create/2`, ...) receive project-wide
      events: connection lifecycle, workflow executions, custom events.
    * **Phone number webhooks** (`*_for_phone_number`) receive message and
      conversation events for one number. `kind: "kapso"` sends Kapso's
      payloads; `kind: "meta"` forwards Meta's payloads unchanged.

  Verify deliveries with `KapsoEx.Webhook`. Event names are listed in
  [Message events](https://docs.kapso.ai/docs/platform/webhooks/message-events)
  and [Project webhooks](https://docs.kapso.ai/docs/platform/webhooks/project-webhooks).
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map() | nil} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists the project's webhooks (project and phone number scoped), most
  recent first. Params: `kind`, `page`, `per_page`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "webhooks"], query: params)
  end

  @doc """
  Creates a project webhook.

  Attributes: `url` (required), `events`, `secret_key`, `active`,
  `headers`, `kind`, `phone_number_id`, `payload_version`, and the
  buffering settings (`buffer_enabled`, `buffer_window_seconds`,
  `max_buffer_size`, `buffer_events`, `inactivity_minutes`).

      Webhooks.create(client, url: "https://example.com/kapso", events: ["whatsapp.phone_number.created"])
  """
  @spec create(Client.t(), map() | keyword()) :: result()
  def create(%Client{} = client, attrs) do
    Request.post(client, :platform, ["whatsapp", "webhooks"],
      json: Request.wrap(attrs, :whatsapp_webhook)
    )
  end

  @doc "Gets a project webhook."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, webhook_id) do
    Request.get(client, :platform, ["whatsapp", "webhooks", webhook_id])
  end

  @doc "Updates a project webhook. Attributes as in `create/2`."
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, webhook_id, attrs) do
    Request.patch(client, :platform, ["whatsapp", "webhooks", webhook_id],
      json: Request.wrap(attrs, :whatsapp_webhook)
    )
  end

  @doc "Deletes a project webhook."
  @spec delete(Client.t(), String.t()) :: result()
  def delete(%Client{} = client, webhook_id) do
    Request.delete(client, :platform, ["whatsapp", "webhooks", webhook_id])
  end

  @doc "Sends a test payload to the webhook URL, optionally for a specific `event_type`."
  @spec test(Client.t(), String.t(), String.t() | nil) :: result()
  def test(%Client{} = client, webhook_id, event_type \\ nil) do
    body = if event_type, do: %{event_type: event_type}, else: %{}
    Request.post(client, :platform, ["whatsapp", "webhooks", webhook_id, "test"], json: body)
  end

  @doc """
  Lists a phone number's webhooks, most recent first.

  Params: `url_contains`, `kind`, `active`, `created_after`,
  `created_before`, `page`, `per_page`.
  """
  @spec list_for_phone_number(Client.t(), String.t(), map() | keyword()) :: result()
  def list_for_phone_number(%Client{} = client, phone_number_id, params \\ []) do
    Request.get(client, :platform, phone_path(phone_number_id), query: params)
  end

  @doc """
  Subscribes a URL to a phone number's events. Attributes as in `create/2`;
  `events` is required for `kind: "kapso"`. Only one `kind: "meta"` webhook
  is allowed per number.

      Webhooks.create_for_phone_number(client, phone_number_id, %{
        url: "https://example.com/kapso",
        events: ["whatsapp.message.received", "whatsapp.message.failed"],
        secret_key: "..."
      })
  """
  @spec create_for_phone_number(Client.t(), String.t(), map() | keyword()) :: result()
  def create_for_phone_number(%Client{} = client, phone_number_id, attrs) do
    Request.post(client, :platform, phone_path(phone_number_id),
      json: Request.wrap(attrs, :whatsapp_webhook)
    )
  end

  @doc "Gets a phone number webhook."
  @spec get_for_phone_number(Client.t(), String.t(), String.t()) :: result()
  def get_for_phone_number(%Client{} = client, phone_number_id, webhook_id) do
    Request.get(client, :platform, phone_path(phone_number_id) ++ [webhook_id])
  end

  @doc "Updates a phone number webhook."
  @spec update_for_phone_number(Client.t(), String.t(), String.t(), map() | keyword()) :: result()
  def update_for_phone_number(%Client{} = client, phone_number_id, webhook_id, attrs) do
    Request.patch(client, :platform, phone_path(phone_number_id) ++ [webhook_id],
      json: Request.wrap(attrs, :whatsapp_webhook)
    )
  end

  @doc "Deletes a phone number webhook."
  @spec delete_for_phone_number(Client.t(), String.t(), String.t()) :: result()
  def delete_for_phone_number(%Client{} = client, phone_number_id, webhook_id) do
    Request.delete(client, :platform, phone_path(phone_number_id) ++ [webhook_id])
  end

  defp phone_path(phone_number_id), do: ["whatsapp", "phone_numbers", phone_number_id, "webhooks"]
end
