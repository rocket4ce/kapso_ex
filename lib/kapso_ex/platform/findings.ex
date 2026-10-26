defmodule KapsoEx.Platform.Findings do
  @moduledoc """
  [Findings](https://docs.kapso.ai/docs/platform/findings): recurring
  problems Kapso detects in your conversations, with AI investigations.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc "Lists findings, most recently qualified first. Params: `limit`, `before`, `after`."
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["findings"], query: params)
  end

  @doc "Gets a finding with its metrics, related findings, verification and investigation."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, finding_id) do
    Request.get(client, :platform, ["findings", finding_id])
  end

  @doc "Gets the evidence behind a finding: history, source events and affected conversations."
  @spec evidence(Client.t(), String.t()) :: result()
  def evidence(%Client{} = client, finding_id) do
    Request.get(client, :platform, ["findings", finding_id, "evidence"])
  end

  @doc "Queues an AI investigation. Poll `get/2` for the result."
  @spec start_investigation(Client.t(), String.t()) :: result()
  def start_investigation(%Client{} = client, finding_id) do
    Request.post(client, :platform, ["findings", finding_id, "start_investigation"])
  end

  @doc """
  Dismisses a finding. `reason` is one of `"not_relevant"`,
  `"expected_behavior"`, `"already_fixed"`, `"incorrect"` or `"other"`.
  """
  @spec dismiss(Client.t(), String.t(), String.t(), String.t()) :: result()
  def dismiss(%Client{} = client, finding_id, reason, note) do
    Request.post(client, :platform, ["findings", finding_id, "dismiss"],
      json: %{reason: reason, note: note}
    )
  end

  @doc """
  Marks a finding as addressed and starts monitoring it. Requires a
  completed investigation that covers the current evidence.
  """
  @spec mark_addressed(Client.t(), String.t()) :: result()
  def mark_addressed(%Client{} = client, finding_id) do
    Request.post(client, :platform, ["findings", finding_id, "mark_addressed"])
  end
end
