defmodule KapsoEx.Workflows.Executions do
  @moduledoc """
  [Start and resume](https://docs.kapso.ai/docs/workflows/start-and-resume-via-api)
  workflow executions and read their history.

  Starting executions has an extra per-workflow burst limit (5 to 30 per
  second depending on the plan); exceeding it returns `429` with
  `retry_after: 1` in the `KapsoEx.Error`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists a workflow's executions, most recent first.

  Params: `status`, `created_after`, `created_before`,
  `whatsapp_conversation_id`, `limit`, `before`, `after`.
  """
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, workflow_id, params \\ []) do
    Request.get(client, :platform, ["workflows", workflow_id, "executions"], query: params)
  end

  @doc """
  Starts an execution asynchronously (`202`, with an `id` and
  `tracking_id`). The workflow must be active.

  Attributes: `phone_number` (E.164) and/or `recipient` (business-scoped
  user ID), `phone_number_id`, `variables`, `context`, `initial_data`.

      Executions.start(client, workflow_id,
        phone_number: "+56961567267",
        phone_number_id: "647015955153740",
        variables: %{order_id: "ORD-1234"}
      )
  """
  @spec start(Client.t(), String.t(), map() | keyword()) :: result()
  def start(%Client{} = client, workflow_id, attrs) do
    Request.post(client, :platform, ["workflows", workflow_id, "executions"],
      json: Request.wrap(attrs, :workflow_execution)
    )
  end

  @doc "Gets an execution with its context, variables and event history."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, execution_id) do
    Request.get(client, :platform, ["workflow_executions", execution_id])
  end

  @doc "Sets the status of an execution: `\"ended\"`, `\"handoff\"` or `\"waiting\"`."
  @spec update_status(Client.t(), String.t(), String.t()) :: result()
  def update_status(%Client{} = client, execution_id, status) do
    Request.patch(client, :platform, ["workflow_executions", execution_id],
      json: Request.wrap(%{status: status}, :workflow_execution)
    )
  end

  @doc "Lists an execution's events, most recent first. Params: `event_type`, `limit`, `before`, `after`."
  @spec list_events(Client.t(), String.t(), map() | keyword()) :: result()
  def list_events(%Client{} = client, execution_id, params \\ []) do
    Request.get(client, :platform, ["workflow_executions", execution_id, "events"], query: params)
  end

  @doc """
  Resumes an execution in `waiting` status (for example at a wait for
  response step), delivering `data` as the incoming message.

  `data` is a string, map or list.

  ## Options

    * `:kind` - message kind, for example `"text"`.
    * `:variables` - variables to merge into the execution.

  ## Examples

      Executions.resume(client, execution_id, "yes", kind: "text", variables: %{confirmed: true})
  """
  @spec resume(Client.t(), String.t(), String.t() | map() | list(), keyword()) :: result()
  def resume(%Client{} = client, execution_id, data, opts \\ []) do
    message = if kind = opts[:kind], do: %{kind: kind, data: data}, else: %{data: data}

    body =
      if vars = opts[:variables],
        do: %{message: message, variables: vars},
        else: %{message: message}

    Request.post(client, :platform, ["workflow_executions", execution_id, "resume"], json: body)
  end

  @doc """
  Lists the workflow executions of a WhatsApp conversation, most recent
  first. Params: `status`, `limit`, `before`, `after`.
  """
  @spec list_for_conversation(Client.t(), String.t(), map() | keyword()) :: result()
  def list_for_conversation(%Client{} = client, conversation_id, params \\ []) do
    path = ["whatsapp", "conversations", conversation_id, "flow_executions"]
    Request.get(client, :platform, path, query: params)
  end
end
