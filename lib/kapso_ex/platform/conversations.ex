defmodule KapsoEx.Platform.Conversations do
  @moduledoc """
  Query conversations across the project, close or reopen them, and assign
  them to team members.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists conversations, latest activity first, with cursor pagination.

  Params: `phone_number_id`, `phone_number`, `status`, `assigned_user_id`,
  `unassigned`, `created_after`, `created_before`, `last_active_after`,
  `last_active_before`, `limit`, `before`, `after`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["whatsapp", "conversations"], query: params)
  end

  @doc "Gets a conversation."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, conversation_id) do
    Request.get(client, :platform, ["whatsapp", "conversations", conversation_id])
  end

  @doc "Closes (`\"ended\"`) or reopens (`\"active\"`) a conversation."
  @spec update_status(Client.t(), String.t(), String.t()) :: result()
  def update_status(%Client{} = client, conversation_id, status) do
    Request.patch(client, :platform, ["whatsapp", "conversations", conversation_id],
      json: Request.wrap(%{status: status}, :whatsapp_conversation)
    )
  end

  @doc "Lists a conversation's assignments, most recent first. Params: `page`, `per_page`."
  @spec list_assignments(Client.t(), String.t(), map() | keyword()) :: result()
  def list_assignments(%Client{} = client, conversation_id, params \\ []) do
    Request.get(client, :platform, assignments_path(conversation_id), query: params)
  end

  @doc """
  Assigns a conversation to a team member. Attributes: `user_id`
  (required), `notes`. Only one active assignment is allowed.
  """
  @spec create_assignment(Client.t(), String.t(), map() | keyword()) :: result()
  def create_assignment(%Client{} = client, conversation_id, attrs) do
    Request.post(client, :platform, assignments_path(conversation_id),
      json: Request.wrap(attrs, :assignment)
    )
  end

  @doc "Gets an assignment."
  @spec get_assignment(Client.t(), String.t(), String.t()) :: result()
  def get_assignment(%Client{} = client, conversation_id, assignment_id) do
    Request.get(client, :platform, assignments_path(conversation_id) ++ [assignment_id])
  end

  @doc """
  Updates an assignment: change `notes`, reassign with `user_id`, or
  unassign with `active: false`.
  """
  @spec update_assignment(Client.t(), String.t(), String.t(), map() | keyword()) :: result()
  def update_assignment(%Client{} = client, conversation_id, assignment_id, attrs) do
    Request.patch(client, :platform, assignments_path(conversation_id) ++ [assignment_id],
      json: Request.wrap(attrs, :assignment)
    )
  end

  defp assignments_path(conversation_id),
    do: ["whatsapp", "conversations", conversation_id, "assignments"]
end
