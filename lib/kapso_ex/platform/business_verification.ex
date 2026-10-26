defmodule KapsoEx.Platform.BusinessVerification do
  @moduledoc """
  Submit a customer's business documents to Meta for
  [business verification](https://docs.kapso.ai/docs/platform/business-verification).

  A portfolio gets 3 attempts. Each submission carries 1 to 3 PDF, JPEG or
  PNG documents of 5 MB or less.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc "Gets the verification status, eligibility, attempts and latest submission."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, portfolio_id) do
    Request.get(client, :platform, path(portfolio_id))
  end

  @doc "Lists your project's submissions for the portfolio, newest first. Params: `limit`, `before`, `after`."
  @spec list_submissions(Client.t(), String.t(), map() | keyword()) :: result()
  def list_submissions(%Client{} = client, portfolio_id, params \\ []) do
    Request.get(client, :platform, path(portfolio_id) ++ ["submissions"], query: params)
  end

  @doc """
  Sends documents to Meta.

  Each document is a map with `:roles` (for example `["legal_name"]` or
  `["address"]`) and either:

    * `:source_url` - an HTTPS URL Kapso downloads, or
    * `:file` - `{content, filename: "certificate.pdf", content_type: "application/pdf"}`,
      sent as multipart.

  `idempotency_key` is required: after a timeout, retry with the same key
  and the same documents. Use a new key only for a new attempt, and never
  while the state is `outcome_unknown`.

  `202` means Kapso accepted the request, not that Meta verified the
  business; check `state` and poll `get_submission/3`.

      key = "verification-" <> portfolio_id <> "-1"

      BusinessVerification.create_submission(client, portfolio_id, [
        %{source_url: "https://files.example.com/certificate.pdf", roles: ["legal_name"]},
        %{file: {File.read!("statement.pdf"), filename: "statement.pdf"}, roles: ["address"]}
      ], key)
  """
  @spec create_submission(Client.t(), String.t(), [map()], String.t()) :: result()
  def create_submission(%Client{} = client, portfolio_id, documents, idempotency_key)
      when is_list(documents) do
    documents = Enum.map(documents, &Request.to_map/1)
    headers = [{"idempotency-key", idempotency_key}]
    path = path(portfolio_id) ++ ["submissions"]

    if Enum.any?(documents, &Map.has_key?(&1, :file)) do
      Request.post(client, :platform, path,
        form_multipart: multipart(documents),
        headers: headers
      )
    else
      Request.post(client, :platform, path, json: %{documents: documents}, headers: headers)
    end
  end

  @doc "Gets a submission with its documents and Meta's rejection reasons."
  @spec get_submission(Client.t(), String.t(), String.t()) :: result()
  def get_submission(%Client{} = client, portfolio_id, submission_id) do
    Request.get(client, :platform, path(portfolio_id) ++ ["submissions", submission_id])
  end

  defp path(portfolio_id), do: ["whatsapp", "portfolios", portfolio_id, "business_verification"]

  # Rails-style nested fields: documents[][file], documents[][roles][]
  defp multipart(documents) do
    Enum.flat_map(documents, fn document ->
      source =
        case document do
          %{file: file} -> [{"documents[][file]", file}]
          %{source_url: url} -> [{"documents[][source_url]", url}]
        end

      source ++ Enum.map(document[:roles] || [], &{"documents[][roles][]", &1})
    end)
  end
end
