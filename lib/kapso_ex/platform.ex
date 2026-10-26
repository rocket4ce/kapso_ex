defmodule KapsoEx.Platform do
  @moduledoc """
  The Platform API (`https://api.kapso.ai/platform/v1`): everything around
  the messages, such as onboarding customers, connecting numbers, setup
  links, broadcasts, webhooks and project data.

  ## Conventions

    * Functions take attributes as maps or keyword lists. When an endpoint
      expects the attributes under a root key (for example
      `{"customer": {...}}`), the function adds it for you:

          KapsoEx.Platform.Customers.create(client, %{name: "Acme", external_customer_id: "acme-1"})
          # POST /customers  {"customer": {"name": "Acme", "external_customer_id": "acme-1"}}

    * Responses keep Kapso's envelope: `%{"data" => ...}`, plus `"meta"`
      (page based lists) or `"paging"` (cursor based lists). Use
      `KapsoEx.Pagination.stream/2` to walk all pages.

  Modules:

    * `KapsoEx.Platform.Customers`, `KapsoEx.Platform.SetupLinks`
    * `KapsoEx.Platform.PhoneNumbers`, `KapsoEx.Platform.DisplayNames`
    * `KapsoEx.Platform.Webhooks`, `KapsoEx.Platform.WebhookDeliveries`
    * `KapsoEx.Platform.Broadcasts`
    * `KapsoEx.Platform.Messages`, `KapsoEx.Platform.Conversations`,
      `KapsoEx.Platform.Contacts`, `KapsoEx.Platform.Media`
    * `KapsoEx.Platform.Flows`
    * `KapsoEx.Platform.Events`, `KapsoEx.Platform.Findings`
    * `KapsoEx.Platform.Users`, `KapsoEx.Platform.InboxEmbeds`,
      `KapsoEx.Platform.Notifications`, `KapsoEx.Platform.ProviderModels`
    * `KapsoEx.Platform.ApiLogs`, `KapsoEx.Platform.LogSearch`
    * `KapsoEx.Platform.Funding`, `KapsoEx.Platform.BusinessVerification`
  """
end
