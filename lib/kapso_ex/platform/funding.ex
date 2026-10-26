defmodule KapsoEx.Platform.Funding do
  @moduledoc """
  [WhatsApp funding and usage](https://docs.kapso.ai/docs/platform/whatsapp-funding)
  for Tech Providers with managed billing: funding status per WhatsApp
  Business Account (WABA) and portfolio, recorded charges, and stopping
  funding.

  Usage amounts are in micro USD (`customer_charge_micro_usd`).
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}
  @type time :: DateTime.t() | String.t()

  @doc "Gets the funding status of a WABA."
  @spec get_account_funding(Client.t(), String.t()) :: result()
  def get_account_funding(%Client{} = client, waba_id) do
    Request.get(client, :platform, ["whatsapp", "accounts", waba_id, "funding"])
  end

  @doc """
  Verifies an external multi-partner solution account with Meta and ensures
  Kapso funds it, without waiting for Meta's webhook. Call it after
  Embedded Signup completes.
  """
  @spec ensure_account_funding(Client.t(), String.t(), String.t()) :: result()
  def ensure_account_funding(%Client{} = client, waba_id, business_portfolio_id) do
    Request.post(client, :platform, ["whatsapp", "accounts", waba_id, "funding"],
      json: %{business_portfolio_id: business_portfolio_id}
    )
  end

  @doc "Gets the charges recorded for a WABA between `start_time` and `end_time`."
  @spec get_account_usage(Client.t(), String.t(), time(), time()) :: result()
  def get_account_usage(%Client{} = client, waba_id, start_time, end_time) do
    Request.get(client, :platform, ["whatsapp", "accounts", waba_id, "usage"],
      query: [start_time: start_time, end_time: end_time]
    )
  end

  @doc "Lists the WABAs of a business portfolio with their funding status. Params: `limit`, `before`, `after`."
  @spec list_portfolio_accounts(Client.t(), String.t(), map() | keyword()) :: result()
  def list_portfolio_accounts(%Client{} = client, portfolio_id, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "portfolios", portfolio_id, "accounts"],
      query: params
    )
  end

  @doc "Gets the charges recorded across a portfolio's accounts between `start_time` and `end_time`."
  @spec get_portfolio_usage(Client.t(), String.t(), time(), time()) :: result()
  def get_portfolio_usage(%Client{} = client, portfolio_id, start_time, end_time) do
    Request.get(client, :platform, ["whatsapp", "portfolios", portfolio_id, "usage"],
      query: [start_time: start_time, end_time: end_time]
    )
  end

  @doc """
  Queues an asynchronous stop of Kapso funding for a portfolio.

  `idempotency_key` (1-255 bytes) must be stable per logical request:
  reuse it when retrying after a network failure to get the original
  operation back. Follow it with `get_funding_operation/3`.
  """
  @spec revoke_portfolio_funding(Client.t(), String.t(), String.t()) :: result()
  def revoke_portfolio_funding(%Client{} = client, portfolio_id, idempotency_key) do
    Request.post(client, :platform, ["whatsapp", "portfolios", portfolio_id, "funding", "revoke"],
      headers: [{"idempotency-key", idempotency_key}]
    )
  end

  @doc "Gets the status of a funding revocation operation."
  @spec get_funding_operation(Client.t(), String.t(), String.t()) :: result()
  def get_funding_operation(%Client{} = client, portfolio_id, operation_id) do
    Request.get(client, :platform, [
      "whatsapp",
      "portfolios",
      portfolio_id,
      "funding",
      "operations",
      operation_id
    ])
  end
end
