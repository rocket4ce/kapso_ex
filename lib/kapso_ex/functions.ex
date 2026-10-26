defmodule KapsoEx.Functions do
  @moduledoc """
  [Functions](https://docs.kapso.ai/docs/functions/overview): serverless
  JavaScript deployed by Kapso, invoked over the API or from workflows.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, term()} | {:error, KapsoEx.Error.t()}

  @doc "Lists the project's functions."
  @spec list(Client.t()) :: result()
  def list(%Client{} = client) do
    Request.get(client, :platform, ["functions"])
  end

  @doc """
  Creates a draft function (not deployed yet).

  Attributes: `name`, `code` and `function_type` (`"cloudflare_worker"` or
  `"supabase_function"`) are required; also `slug`, `description`,
  `public_endpoint`, `runtime_config`.
  """
  @spec create(Client.t(), map() | keyword()) :: result()
  def create(%Client{} = client, attrs) do
    Request.post(client, :platform, ["functions"], json: Request.wrap(attrs, :function))
  end

  @doc "Gets a function with its code, deployment status and URLs."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, function_id) do
    Request.get(client, :platform, ["functions", function_id])
  end

  @doc """
  Updates a function (partial). Attributes: `name`, `slug`, `description`,
  `code`, `invoke_response_mode`, `runtime_config`, `public_endpoint`, and
  `lock_version` for optimistic locking.
  """
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, function_id, attrs) do
    Request.patch(client, :platform, ["functions", function_id],
      json: Request.wrap(attrs, :function)
    )
  end

  @doc "Deletes a function, its deployment and its secrets."
  @spec delete(Client.t(), String.t()) :: result()
  def delete(%Client{} = client, function_id) do
    Request.delete(client, :platform, ["functions", function_id])
  end

  @doc "Deploys a function in the background (usually 10-60 seconds). Poll `get/2` for the status."
  @spec deploy(Client.t(), String.t()) :: result()
  def deploy(%Client{} = client, function_id) do
    Request.post(client, :platform, ["functions", function_id, "deploy"])
  end

  @doc """
  Invokes a deployed function with `payload` as the request body. Returns
  the function's response (JSON decoded when it is JSON).
  """
  @spec invoke(Client.t(), String.t(), map() | list()) :: result()
  def invoke(%Client{} = client, function_id, payload \\ %{}) do
    Request.post(client, :platform, ["functions", function_id, "invoke"], json: payload)
  end

  @doc "Lists secret names (never values)."
  @spec list_secrets(Client.t(), String.t()) :: result()
  def list_secrets(%Client{} = client, function_id) do
    Request.get(client, :platform, ["functions", function_id, "secrets"])
  end

  @doc "Creates a secret, exposed to the function as an environment variable."
  @spec create_secret(Client.t(), String.t(), String.t(), String.t() | map()) :: result()
  def create_secret(%Client{} = client, function_id, name, value) do
    Request.post(client, :platform, ["functions", function_id, "secrets"],
      json: Request.wrap(%{name: name, value: value}, :secret)
    )
  end

  @doc "Deletes a secret."
  @spec delete_secret(Client.t(), String.t(), String.t()) :: result()
  def delete_secret(%Client{} = client, function_id, name) do
    Request.delete(client, :platform, ["functions", function_id, "secrets", name])
  end

  @doc "Lists recent invocations with captured console logs. Params: `status`, `limit`."
  @spec list_invocations(Client.t(), String.t(), map() | keyword()) :: result()
  def list_invocations(%Client{} = client, function_id, params \\ []) do
    Request.get(client, :platform, ["functions", function_id, "invocations"], query: params)
  end
end
