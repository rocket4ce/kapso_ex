defmodule KapsoEx.Platform.ApiLogs do
  @moduledoc "Logs of the API calls made with your project's keys."

  alias KapsoEx.{Client, Request}

  @doc """
  Lists API logs, most recent first.

  Params: `endpoint`, `status_code`, `errors_only`, `period`, `limit`,
  `before`, `after`.
  """
  @spec list(Client.t(), map() | keyword()) :: {:ok, map()} | {:error, KapsoEx.Error.t()}
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["api_logs"], query: params)
  end
end
