defmodule KapsoEx.Platform.Customers do
  @moduledoc """
  Customers are the businesses you onboard to WhatsApp. See
  [Onboard customers](https://docs.kapso.ai/docs/platform/customer-guide).
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map() | nil} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists customers, most recent first.

  Params: `name_contains`, `external_customer_id`, `created_after`,
  `created_before`, `page`, `per_page`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["customers"], query: params)
  end

  @doc """
  Creates a customer. Attributes: `name` (required), `external_customer_id`.

      Customers.create(client, name: "Acme", external_customer_id: "acme-1")
  """
  @spec create(Client.t(), map() | keyword()) :: result()
  def create(%Client{} = client, attrs) do
    Request.post(client, :platform, ["customers"], json: Request.wrap(attrs, :customer))
  end

  @doc "Gets a customer."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, customer_id) do
    Request.get(client, :platform, ["customers", customer_id])
  end

  @doc "Updates a customer's `name` or `external_customer_id`."
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, customer_id, attrs) do
    Request.patch(client, :platform, ["customers", customer_id],
      json: Request.wrap(attrs, :customer)
    )
  end

  @doc "Deletes a customer."
  @spec delete(Client.t(), String.t()) :: result()
  def delete(%Client{} = client, customer_id) do
    Request.delete(client, :platform, ["customers", customer_id])
  end
end
