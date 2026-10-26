defmodule KapsoEx.Platform.Broadcasts do
  @moduledoc """
  Send an approved template to many recipients, with per-recipient
  tracking. See the [Broadcasts API guide](https://docs.kapso.ai/docs/platform/broadcasts/api).

  Typical flow:

      {:ok, %{"data" => %{"id" => id}}} =
        Broadcasts.create(client, name: "Black Friday", phone_number_id: pnid, whatsapp_template_id: tid)

      {:ok, _} =
        Broadcasts.add_recipients(client, id, [
          %{phone_number: "+56961567267", components: [%{type: "body", parameters: [%{type: "text", text: "Ana"}]}]}
        ])

      {:ok, _} = Broadcasts.send(client, id)

  Kapso paces sends to stay within Meta's throughput limits.
  """

  import Kernel, except: [send: 2]

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists broadcasts, most recent first.

  Params: `phone_number_id`, `status`, `created_after`, `created_before`,
  `page`, `per_page`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "broadcasts"], query: params)
  end

  @doc """
  Creates a draft broadcast. Attributes: `name`, `phone_number_id` and
  `whatsapp_template_id` (all required).
  """
  @spec create(Client.t(), map() | keyword()) :: result()
  def create(%Client{} = client, attrs) do
    Request.post(client, :platform, ["whatsapp", "broadcasts"],
      json: Request.wrap(attrs, :whatsapp_broadcast)
    )
  end

  @doc "Gets a broadcast with its delivery counters. Poll it to follow progress."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, broadcast_id) do
    Request.get(client, :platform, ["whatsapp", "broadcasts", broadcast_id])
  end

  @doc "Changes the status of a broadcast: `\"stopped\"` or back to `\"draft\"`."
  @spec update_status(Client.t(), String.t(), String.t()) :: result()
  def update_status(%Client{} = client, broadcast_id, status) do
    Request.patch(client, :platform, ["whatsapp", "broadcasts", broadcast_id],
      json: Request.wrap(%{status: status}, :whatsapp_broadcast)
    )
  end

  @doc "Lists recipients with their delivery status. Params: `page`, `per_page`."
  @spec list_recipients(Client.t(), String.t(), map() | keyword()) :: result()
  def list_recipients(%Client{} = client, broadcast_id, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "broadcasts", broadcast_id, "recipients"],
      query: params
    )
  end

  @doc """
  Adds up to 1000 recipients to a draft broadcast. Duplicates are skipped.

  Each recipient is a map with `phone_number` (E.164) or
  `whatsapp_contact_id` and, when the template has parameters,
  `components` (see `KapsoEx.WhatsApp.TemplateComponents`).
  """
  @spec add_recipients(Client.t(), String.t(), [map()]) :: result()
  def add_recipients(%Client{} = client, broadcast_id, recipients) when is_list(recipients) do
    Request.post(client, :platform, ["whatsapp", "broadcasts", broadcast_id, "recipients"],
      json: Request.wrap(%{recipients: recipients}, :whatsapp_broadcast)
    )
  end

  @doc "Removes every recipient from a draft or scheduled broadcast."
  @spec clear_recipients(Client.t(), String.t()) :: result()
  def clear_recipients(%Client{} = client, broadcast_id) do
    Request.delete(client, :platform, ["whatsapp", "broadcasts", broadcast_id, "recipients"])
  end

  @doc "Starts sending now. Sending is asynchronous; poll `get/2` for progress."
  @spec send(Client.t(), String.t()) :: result()
  def send(%Client{} = client, broadcast_id) do
    Request.post(client, :platform, ["whatsapp", "broadcasts", broadcast_id, "send"])
  end

  @doc """
  Schedules a draft broadcast with recipients. `scheduled_at` is a
  `DateTime` or an ISO 8601 string.
  """
  @spec schedule(Client.t(), String.t(), DateTime.t() | String.t()) :: result()
  def schedule(%Client{} = client, broadcast_id, scheduled_at) do
    Request.post(client, :platform, ["whatsapp", "broadcasts", broadcast_id, "schedule"],
      json: %{scheduled_at: scheduled_at}
    )
  end

  @doc "Cancels a scheduled broadcast and returns it to draft."
  @spec cancel(Client.t(), String.t()) :: result()
  def cancel(%Client{} = client, broadcast_id) do
    Request.post(client, :platform, ["whatsapp", "broadcasts", broadcast_id, "cancel"])
  end
end
