defmodule KapsoEx.Platform.Users do
  @moduledoc "Members of your Kapso project, for example to assign conversations."

  alias KapsoEx.{Client, Request}

  @doc "Lists project members. Params: `page`, `per_page`."
  @spec list(Client.t(), map() | keyword()) :: {:ok, map()} | {:error, KapsoEx.Error.t()}
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["users"], query: params)
  end
end
