defmodule KapsoEx.Platform.ProviderModels do
  @moduledoc "AI provider models available to agent nodes and Kapso Agent modes."

  alias KapsoEx.{Client, Request}

  @doc "Lists the available AI provider models."
  @spec list(Client.t()) :: {:ok, map()} | {:error, KapsoEx.Error.t()}
  def list(%Client{} = client) do
    Request.get(client, :platform, ["provider_models"])
  end
end
