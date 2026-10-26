defmodule KapsoEx.WhatsApp.Flows do
  @moduledoc """
  WhatsApp Flows through Meta's Graph API shapes (proxied by Kapso).

  `KapsoEx.Platform.Flows` offers a higher level API on top of this: flow
  versions, data endpoints and encryption setup.

  Flow-ID endpoints need a context so Kapso can pick the connection: pass
  `phone_number_id:` or `business_account_id:` in `params`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @default_fields "id,name,status,categories,validation_errors,json_version,data_api_version,endpoint_uri,preview"

  @doc "Lists the flows of a WhatsApp Business Account."
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, business_account_id, params \\ []) do
    Request.get(client, :whatsapp, [business_account_id, "flows"], query: params)
  end

  @doc """
  Creates a flow in a WhatsApp Business Account.

  Attributes: `name` and `categories` (required), `clone_flow_id`,
  `endpoint_uri`, `flow_json` (a JSON string) and `publish`.
  """
  @spec create(Client.t(), String.t(), map() | keyword()) :: result()
  def create(%Client{} = client, business_account_id, attrs) do
    Request.post(client, :whatsapp, [business_account_id, "flows"], json: attrs)
  end

  @doc "Lists the flows available to a phone number."
  @spec list_for_phone_number(Client.t(), String.t(), map() | keyword()) :: result()
  def list_for_phone_number(%Client{} = client, phone_number_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "flows"], query: params)
  end

  @doc "Creates a flow for a phone number. Attributes as in `create/3`."
  @spec create_for_phone_number(Client.t(), String.t(), map() | keyword()) :: result()
  def create_for_phone_number(%Client{} = client, phone_number_id, attrs) do
    Request.post(client, :whatsapp, [phone_number_id, "flows"], json: attrs)
  end

  @doc """
  Gets a flow. `fields` defaults to
  `#{inspect(@default_fields)}`.

      Flows.get(client, flow_id, phone_number_id: "647015955153740")
  """
  @spec get(Client.t(), String.t(), map() | keyword()) :: result()
  def get(%Client{} = client, flow_id, params) do
    params = params |> Map.new() |> Map.put_new(:fields, @default_fields)
    Request.get(client, :whatsapp, [flow_id], query: params)
  end

  @doc """
  Updates flow metadata: `name`, `categories`, `endpoint_uri` or
  `application_id`.
  """
  @spec update(Client.t(), String.t(), map() | keyword(), map() | keyword()) :: result()
  def update(%Client{} = client, flow_id, attrs, params \\ []) do
    Request.post(client, :whatsapp, [flow_id], query: params, json: attrs)
  end

  @doc "Lists the flow's assets, with download URLs for the flow JSON."
  @spec get_assets(Client.t(), String.t(), map() | keyword()) :: result()
  def get_assets(%Client{} = client, flow_id, params \\ []) do
    Request.get(client, :whatsapp, [flow_id, "assets"], query: params)
  end

  @doc """
  Uploads the flow JSON (max 10 MB). `flow_json` is a JSON string or a map,
  which is encoded for you.
  """
  @spec upload_json(Client.t(), String.t(), String.t() | map(), map() | keyword()) :: result()
  def upload_json(%Client{} = client, flow_id, flow_json, params \\ []) do
    json = if is_binary(flow_json), do: flow_json, else: Jason.encode!(flow_json)

    Request.post(client, :whatsapp, [flow_id, "assets"],
      query: params,
      form_multipart: [
        name: "flow.json",
        asset_type: "FLOW_JSON",
        file: {json, filename: "flow.json", content_type: "application/json"}
      ]
    )
  end

  @doc "Publishes a flow. This cannot be undone."
  @spec publish(Client.t(), String.t(), map() | keyword()) :: result()
  def publish(%Client{} = client, flow_id, params \\ []) do
    Request.post(client, :whatsapp, [flow_id, "publish"], query: params)
  end

  @doc "Deprecates a published flow."
  @spec deprecate(Client.t(), String.t(), map() | keyword()) :: result()
  def deprecate(%Client{} = client, flow_id, params \\ []) do
    Request.post(client, :whatsapp, [flow_id, "deprecate"], query: params)
  end

  @doc "Deletes a draft flow. This cannot be undone."
  @spec delete(Client.t(), String.t(), map() | keyword()) :: result()
  def delete(%Client{} = client, flow_id, params \\ []) do
    Request.delete(client, :whatsapp, ["flows", flow_id], query: params)
  end
end
