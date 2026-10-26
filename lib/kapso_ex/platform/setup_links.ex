defmodule KapsoEx.Platform.SetupLinks do
  @moduledoc """
  Setup links are hosted onboarding pages where a customer connects their
  WhatsApp number. See
  [Create and configure](https://docs.kapso.ai/docs/platform/setup-links/create-and-configure).
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists a customer's setup links, most recent first.

  Params: `status`, `created_after`, `created_before`, `page`, `per_page`.
  """
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, customer_id, params \\ []) do
    Request.get(client, :platform, ["customers", customer_id, "setup_links"], query: params)
  end

  @doc """
  Creates a setup link. The response `data.url` is the page to send to the
  customer.

  Attributes include `success_redirect_url`, `failure_redirect_url`,
  `allowed_origins`, `allowed_connection_types`, `provision_phone_number`,
  `phone_number_area_code`, `phone_number_country_isos`,
  `meta_billing_mode`, `theme_config`, `reconnect_phone_number` and
  `language`.

      SetupLinks.create(client, customer_id, %{
        success_redirect_url: "https://app.example.com/whatsapp/connected",
        language: "es"
      })
  """
  @spec create(Client.t(), String.t(), map() | keyword()) :: result()
  def create(%Client{} = client, customer_id, attrs \\ %{}) do
    Request.post(client, :platform, ["customers", customer_id, "setup_links"],
      json: Request.wrap(attrs, :setup_link)
    )
  end

  @doc """
  Updates a setup link. Besides the `create/3` attributes, accepts
  `expires_at` and `status` (for example `"revoked"`).
  """
  @spec update(Client.t(), String.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, customer_id, setup_link_id, attrs) do
    Request.patch(client, :platform, ["customers", customer_id, "setup_links", setup_link_id],
      json: Request.wrap(attrs, :setup_link)
    )
  end
end
