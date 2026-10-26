defmodule KapsoEx.Workflows do
  @moduledoc """
  [Workflows](https://docs.kapso.ai/docs/workflows/introduction): automated
  WhatsApp conversations built from nodes and edges.

  Executions are in `KapsoEx.Workflows.Executions` and triggers in
  `KapsoEx.Workflows.Triggers`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists workflows, newest first.

  Params: `status`, `name_contains`, `created_after`, `created_before`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["workflows"], query: params)
  end

  @doc """
  Creates a draft workflow. Attributes: `name` (required), `slug`,
  `description`, `definition` (`%{nodes: [...], edges: [...]}`).
  """
  @spec create(Client.t(), map() | keyword()) :: result()
  def create(%Client{} = client, attrs) do
    Request.post(client, :platform, ["workflows"], json: Request.wrap(attrs, :workflow))
  end

  @doc "Gets workflow metadata, status and execution stats (without the definition)."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, workflow_id) do
    Request.get(client, :platform, ["workflows", workflow_id])
  end

  @doc """
  Updates a workflow. Attributes: `name`, `slug`, `description`, `status`
  (`"draft"`, `"active"`, `"archived"`), `message_debounce_seconds`,
  `inbound_message_read_mode`, `definition`, and `lock_version` for
  optimistic locking.

      Workflows.update(client, workflow_id, status: "active")
  """
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, workflow_id, attrs) do
    Request.patch(client, :platform, ["workflows", workflow_id],
      json: Request.wrap(attrs, :workflow)
    )
  end

  @doc "Gets the workflow with its editor definition (nodes and edges)."
  @spec get_definition(Client.t(), String.t()) :: result()
  def get_definition(%Client{} = client, workflow_id) do
    Request.get(client, :platform, ["workflows", workflow_id, "definition"])
  end

  @doc "Gets the system variables and the variables discovered from past executions."
  @spec get_variables(Client.t(), String.t()) :: result()
  def get_variables(%Client{} = client, workflow_id) do
    Request.get(client, :platform, ["workflows", workflow_id, "variables"])
  end
end
