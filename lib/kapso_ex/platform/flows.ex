defmodule KapsoEx.Platform.Flows do
  @moduledoc """
  WhatsApp Flows managed by Kapso: versions, publishing, encryption and
  data endpoints (serverless functions that serve dynamic flow data).

  See [Flows in Kapso](https://docs.kapso.ai/docs/whatsapp/flows/kapso-integration).
  To send a flow, use `KapsoEx.WhatsApp.Messages.send_flow/6`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists flows, most recent first.

  Params: `status`, `business_account_id`, `phone_number_id`,
  `name_contains`, `created_after`, `created_before`, `page`, `per_page`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "flows"], query: params)
  end

  @doc """
  Creates a flow. Attributes: `phone_number_id` (required), `name`,
  `flow_json` (a map; defaults to a basic welcome screen) and `publish`.
  """
  @spec create(Client.t(), map() | keyword()) :: result()
  def create(%Client{} = client, attrs) do
    Request.post(client, :platform, ["whatsapp", "flows"], json: attrs)
  end

  @doc "Gets a flow."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, flow_id) do
    Request.get(client, :platform, ["whatsapp", "flows", flow_id])
  end

  @doc "Publishes a draft flow. Published flows cannot be unpublished. Attributes: `phone_number_id`."
  @spec publish(Client.t(), String.t(), map() | keyword()) :: result()
  def publish(%Client{} = client, flow_id, attrs \\ %{}) do
    Request.post(client, :platform, ["whatsapp", "flows", flow_id, "publish"], json: attrs)
  end

  @doc """
  Sets up flows encryption for the flow's WABA, required by data
  endpoints. Attributes: `phone_number_id`.
  """
  @spec setup_encryption(Client.t(), String.t(), map() | keyword()) :: result()
  def setup_encryption(%Client{} = client, flow_id, attrs \\ %{}) do
    Request.post(client, :platform, ["whatsapp", "flows", flow_id, "setup_encryption"],
      json: attrs
    )
  end

  @doc "Lists flow versions, most recent first. Params: `page`, `per_page`."
  @spec list_versions(Client.t(), String.t(), map() | keyword()) :: result()
  def list_versions(%Client{} = client, flow_id, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "flows", flow_id, "versions"], query: params)
  end

  @doc """
  Uploads new flow JSON as a new version and syncs it with Meta.

  ## Options

    * `:phone_number_id`
  """
  @spec create_version(Client.t(), String.t(), map(), keyword()) :: result()
  def create_version(%Client{} = client, flow_id, flow_json, opts \\ []) do
    attrs =
      opts |> Keyword.take([:phone_number_id]) |> Map.new() |> Map.put(:flow_json, flow_json)

    Request.post(client, :platform, ["whatsapp", "flows", flow_id, "versions"], json: attrs)
  end

  @doc "Gets a flow version, including its flow JSON."
  @spec get_version(Client.t(), String.t(), String.t()) :: result()
  def get_version(%Client{} = client, flow_id, version_id) do
    Request.get(client, :platform, ["whatsapp", "flows", flow_id, "versions", version_id])
  end

  @doc "Gets the data endpoint function of a flow."
  @spec get_data_endpoint(Client.t(), String.t()) :: result()
  def get_data_endpoint(%Client{} = client, flow_id) do
    Request.get(client, :platform, data_endpoint_path(flow_id))
  end

  @doc """
  Creates or updates the data endpoint function code (JavaScript). Deploy
  it with `deploy_data_endpoint/2` and register it with
  `register_data_endpoint/2`.
  """
  @spec put_data_endpoint(Client.t(), String.t(), String.t()) :: result()
  def put_data_endpoint(%Client{} = client, flow_id, code) do
    Request.post(client, :platform, data_endpoint_path(flow_id), json: %{code: code})
  end

  @doc """
  Attaches an existing deployed function as the flow's data endpoint and
  registers it with Meta. Several flows can share one function.
  """
  @spec attach_data_endpoint(Client.t(), String.t(), String.t()) :: result()
  def attach_data_endpoint(%Client{} = client, flow_id, function_id) do
    Request.patch(client, :platform, data_endpoint_path(flow_id),
      json: %{function_id: function_id}
    )
  end

  @doc "Deploys the data endpoint function."
  @spec deploy_data_endpoint(Client.t(), String.t()) :: result()
  def deploy_data_endpoint(%Client{} = client, flow_id) do
    Request.post(client, :platform, data_endpoint_path(flow_id) ++ ["deploy"])
  end

  @doc "Registers the deployed data endpoint URL with Meta. Requires flows encryption."
  @spec register_data_endpoint(Client.t(), String.t()) :: result()
  def register_data_endpoint(%Client{} = client, flow_id) do
    Request.post(client, :platform, data_endpoint_path(flow_id) ++ ["register"])
  end

  @doc """
  Gets logs of the data endpoint function (shared functions include every
  flow's activity). Params: `limit`.
  """
  @spec function_logs(Client.t(), String.t(), map() | keyword()) :: result()
  def function_logs(%Client{} = client, flow_id, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "flows", flow_id, "function_logs"], query: params)
  end

  @doc "Gets recent invocations of the data endpoint function. Params: `status`, `limit`."
  @spec function_invocations(Client.t(), String.t(), map() | keyword()) :: result()
  def function_invocations(%Client{} = client, flow_id, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "flows", flow_id, "function_invocations"],
      query: params
    )
  end

  defp data_endpoint_path(flow_id), do: ["whatsapp", "flows", flow_id, "data_endpoint"]
end
