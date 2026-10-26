defmodule KapsoEx.Agent.Modes do
  @moduledoc """
  [Kapso Agent modes](https://docs.kapso.ai/docs/kapso-agent/modes):
  built-in and custom modes with their instructions, tools and
  permissions. Only modes whose `available_invocations` include `"api"`
  accept runs from `KapsoEx.Agent.Runs.create/2`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc "Lists every mode."
  @spec list(Client.t()) :: result()
  def list(%Client{} = client) do
    Request.get(client, :platform, ["kapso-agent", "modes"])
  end

  @doc "Gets a mode by its identifier."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, mode) do
    Request.get(client, :platform, ["kapso-agent", "modes", mode])
  end
end
