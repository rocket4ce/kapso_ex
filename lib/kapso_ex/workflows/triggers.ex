defmodule KapsoEx.Workflows.Triggers do
  @moduledoc """
  [Triggers](https://docs.kapso.ai/docs/flows/triggers) start a workflow
  automatically: on an inbound message, a WhatsApp event, a project event,
  or an API call.

  A trigger map has `trigger_type` (`"inbound_message"`, `"api_call"`,
  `"whatsapp_event"`, `"project_event"`), `active`, and type specific
  fields: `phone_number_id`, `event`, `event_name`, `property_key`,
  `operator` and `property_value`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map() | nil} | {:error, KapsoEx.Error.t()}

  @doc "Lists a workflow's triggers."
  @spec list(Client.t(), String.t()) :: result()
  def list(%Client{} = client, workflow_id) do
    Request.get(client, :platform, ["workflows", workflow_id, "triggers"])
  end

  @doc """
  Creates a trigger.

      Triggers.create(client, workflow_id, trigger_type: "inbound_message", phone_number_id: pnid)
  """
  @spec create(Client.t(), String.t(), map() | keyword()) :: result()
  def create(%Client{} = client, workflow_id, attrs) do
    Request.post(client, :platform, ["workflows", workflow_id, "triggers"],
      json: Request.wrap(attrs, :trigger)
    )
  end

  @doc """
  Atomically replaces every trigger of a workflow. If any trigger is
  invalid, nothing changes.
  """
  @spec replace(Client.t(), String.t(), [map()]) :: result()
  def replace(%Client{} = client, workflow_id, triggers) when is_list(triggers) do
    Request.put(client, :platform, ["workflows", workflow_id, "triggers"],
      json: %{triggers: triggers}
    )
  end

  @doc "Updates a trigger. Only `active` can be changed."
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, trigger_id, attrs) do
    Request.patch(client, :platform, ["triggers", trigger_id],
      json: Request.wrap(attrs, :trigger)
    )
  end

  @doc "Deletes a trigger."
  @spec delete(Client.t(), String.t()) :: result()
  def delete(%Client{} = client, trigger_id) do
    Request.delete(client, :platform, ["triggers", trigger_id])
  end
end
