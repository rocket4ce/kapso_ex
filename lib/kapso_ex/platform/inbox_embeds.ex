defmodule KapsoEx.Platform.InboxEmbeds do
  @moduledoc """
  Access links to [embed the Kapso inbox](https://docs.kapso.ai/docs/platform/inbox/embedded)
  in your own application through an iframe.

  The raw token and embed URL are only returned by `create/2`; store them
  then.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map() | nil} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists inbox embeds, most recent first.

  Params: `status`, `scope_type`, `scope_id`, `assigned_user_id`, `page`,
  `per_page`.
  """
  @spec list(Client.t(), map() | keyword()) :: result()
  def list(%Client{} = client, params \\ []) do
    Request.get(client, :platform, ["inbox_embeds"], query: params)
  end

  @doc """
  Creates an inbox embed.

  Attributes: `scope_type` (required: `"project"`, `"customer"` or
  `"phone_number"`), `scope_id`, `name`, `assigned_user_id`,
  `allowed_origins`, `default_mode` (`"system"`, `"light"`, `"dark"`),
  `language` (`"en"`, `"es"`), `expires_at`.

      InboxEmbeds.create(client, scope_type: "customer", scope_id: customer_id,
        allowed_origins: ["https://app.example.com"], language: "es")
  """
  @spec create(Client.t(), map() | keyword()) :: result()
  def create(%Client{} = client, attrs) do
    Request.post(client, :platform, ["inbox_embeds"], json: Request.wrap(attrs, :inbox_embed))
  end

  @doc "Gets an inbox embed (without its token or URL)."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, inbox_embed_id) do
    Request.get(client, :platform, ["inbox_embeds", inbox_embed_id])
  end

  @doc "Updates an inbox embed. The scope cannot be changed."
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, inbox_embed_id, attrs) do
    Request.patch(client, :platform, ["inbox_embeds", inbox_embed_id],
      json: Request.wrap(attrs, :inbox_embed)
    )
  end

  @doc "Revokes the embed token immediately."
  @spec revoke(Client.t(), String.t()) :: result()
  def revoke(%Client{} = client, inbox_embed_id) do
    Request.delete(client, :platform, ["inbox_embeds", inbox_embed_id])
  end
end
