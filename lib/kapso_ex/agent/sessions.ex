defmodule KapsoEx.Agent.Sessions do
  @moduledoc """
  Kapso Agent sessions: conversations made of runs. Only sessions created
  with the API key in use are visible.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists a mode's sessions, latest activity first. Params: `page`,
  `per_page`, `limit`, `before`, `after`.
  """
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, mode, params \\ []) do
    Request.get(client, :platform, ["kapso-agent", "modes", mode, "sessions"], query: params)
  end

  @doc "Gets a session and its runs, newest first. Params as in `list/3`."
  @spec get(Client.t(), String.t(), map() | keyword()) :: result()
  def get(%Client{} = client, session_id, params \\ []) do
    Request.get(client, :platform, ["kapso-agent", "sessions", session_id], query: params)
  end
end
