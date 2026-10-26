defmodule KapsoEx.Agent.Runs do
  @moduledoc """
  Trigger and control [Kapso Agent](https://docs.kapso.ai/docs/kapso-agent/api)
  runs.

  Runs are asynchronous: poll `get/2` (or the returned `status_url`) or
  subscribe to the `kapso_agent.run.*` project webhooks. When a run is
  `waiting_for_approval`, approve or reject the pending tool call.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Creates a run.

  Attributes: `mode` and `input` (`%{prompt: ...}` or `%{finding_id: ...}`)
  are required; pass `conversation_id` to continue a session (same API key
  and mode), and `metadata` for your own references.

  Built-in modes that accept API runs: `"auto"`, `"api"`, `"workflows"`,
  `"findings"`, `"findings-investigator"`, `"meta-onboarding"`,
  `"whatsapp-templates"` and `"whatsapp-flow"`, plus custom modes with the
  `api` surface. Other modes return `422`.

      Runs.create(client, %{mode: "api", input: %{prompt: "How many conversations failed today?"}})
  """
  @spec create(Client.t(), map() | keyword()) :: result()
  def create(%Client{} = client, attrs) do
    Request.post(client, :platform, ["kapso-agent", "runs"], json: attrs)
  end

  @doc "Gets a run. Only runs created with the same API key are visible."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, run_id) do
    Request.get(client, :platform, ["kapso-agent", "runs", run_id])
  end

  @doc "Pauses a run."
  @spec pause(Client.t(), String.t()) :: result()
  def pause(%Client{} = client, run_id) do
    Request.post(client, :platform, ["kapso-agent", "runs", run_id, "pause"])
  end

  @doc "Resumes a paused run."
  @spec resume(Client.t(), String.t()) :: result()
  def resume(%Client{} = client, run_id) do
    Request.post(client, :platform, ["kapso-agent", "runs", run_id, "resume"])
  end

  @doc "Cancels a run."
  @spec cancel(Client.t(), String.t()) :: result()
  def cancel(%Client{} = client, run_id) do
    Request.post(client, :platform, ["kapso-agent", "runs", run_id, "cancel"])
  end

  @doc "Approves a pending tool call."
  @spec approve(Client.t(), String.t(), String.t()) :: result()
  def approve(%Client{} = client, run_id, approval_id) do
    Request.post(client, :platform, [
      "kapso-agent",
      "runs",
      run_id,
      "approvals",
      approval_id,
      "approve"
    ])
  end

  @doc "Rejects a pending tool call."
  @spec reject(Client.t(), String.t(), String.t()) :: result()
  def reject(%Client{} = client, run_id, approval_id) do
    Request.post(client, :platform, [
      "kapso-agent",
      "runs",
      run_id,
      "approvals",
      approval_id,
      "reject"
    ])
  end
end
