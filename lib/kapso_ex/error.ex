defmodule KapsoEx.Error do
  @moduledoc """
  Returned as `{:error, %KapsoEx.Error{}}` when a request fails.

  ## Fields

    * `:status` - HTTP status code, or `nil` for transport errors.
    * `:message` - human readable message extracted from the response body.
    * `:code` - error code from the body when present. Meta-style errors from
      the WhatsApp API carry an integer code (for example `131047`), Platform
      errors may carry a string code (for example `"findings_not_enabled"`).
    * `:body` - the decoded response body.
    * `:headers` - response headers, a map of lowercase name to list of values.
    * `:retry_after` - seconds from the `Retry-After` header, when present.
      Set on `429` responses.
    * `:reason` - the underlying exception for transport errors (timeouts,
      connection refused, ...).
  """

  defexception [:status, :message, :code, :body, :reason, :retry_after, headers: %{}]

  @type t :: %__MODULE__{
          status: non_neg_integer() | nil,
          message: String.t(),
          code: integer() | String.t() | nil,
          body: term(),
          headers: %{optional(String.t()) => [String.t()]},
          retry_after: non_neg_integer() | nil,
          reason: Exception.t() | nil
        }

  @impl true
  def message(%__MODULE__{status: nil, message: message}), do: message
  def message(%__MODULE__{status: status, message: message}), do: "(HTTP #{status}) #{message}"

  @doc false
  @spec from_response(Req.Response.t()) :: t()
  def from_response(%Req.Response{status: status, body: body, headers: headers}) do
    {message, code} = extract(body)

    %__MODULE__{
      status: status,
      message: message || "request failed with status #{status}",
      code: code,
      body: body,
      headers: headers,
      retry_after: retry_after(headers)
    }
  end

  @doc false
  @spec from_exception(Exception.t()) :: t()
  def from_exception(exception) do
    %__MODULE__{message: Exception.message(exception), reason: exception}
  end

  # Meta Graph API style: %{"error" => %{"message" => ..., "code" => ...}}
  defp extract(%{"error" => %{} = error}), do: {error["message"], error["code"]}

  # Kapso style: %{"error" => "Not found"}, optionally with "message"/"code"
  defp extract(%{"error" => error} = body) when is_binary(error), do: {error, body["code"]}

  defp extract(%{"message" => message} = body) when is_binary(message),
    do: {message, body["code"]}

  defp extract(body) when is_binary(body) and body != "", do: {body, nil}
  defp extract(_body), do: {nil, nil}

  defp retry_after(headers) do
    with [value | _] <- Map.get(headers, "retry-after"),
         {seconds, ""} <- Integer.parse(value) do
      seconds
    else
      _ -> nil
    end
  end
end
