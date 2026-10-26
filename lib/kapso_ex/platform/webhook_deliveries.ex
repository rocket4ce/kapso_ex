defmodule KapsoEx.Platform.WebhookDeliveries do
  @moduledoc "Delivery attempts of your webhooks, useful to debug failures."

  alias KapsoEx.{Client, Request}

  @doc """
  Lists webhook deliveries, most recent first.

  Params: `status`, `event`, `webhook_id`, `errors_only`, `period`, `limit`,
  `before`, `after`.
  """
  @spec list(Client.t(), map() | keyword()) :: {:ok, map()} | {:error, KapsoEx.Error.t()}
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["webhook_deliveries"], query: params)
  end
end
