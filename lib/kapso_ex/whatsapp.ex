defmodule KapsoEx.WhatsApp do
  @moduledoc """
  Helpers shared by the WhatsApp API modules.

  The WhatsApp API (`https://api.kapso.ai/meta/whatsapp/v24.0`) proxies
  Meta's WhatsApp Cloud API, so payloads and responses follow
  [Meta's documentation](https://developers.facebook.com/docs/whatsapp/cloud-api).
  On top of that, Kapso stores history, which lets you list messages,
  conversations, contacts and calls, and adds extra fields when you ask for
  them with `fields=kapso(...)` (see `kapso_fields/1`).

  Modules:

    * `KapsoEx.WhatsApp.Messages` - send and list messages
    * `KapsoEx.WhatsApp.Templates` - message templates
    * `KapsoEx.WhatsApp.TemplateComponents` - build template parameters
    * `KapsoEx.WhatsApp.Media` - upload, inspect, delete and download media
    * `KapsoEx.WhatsApp.Conversations` - stored conversations and thread control
    * `KapsoEx.WhatsApp.Contacts` - stored contacts
    * `KapsoEx.WhatsApp.Calls` - WhatsApp Calling
    * `KapsoEx.WhatsApp.Flows` - WhatsApp Flows (Meta Graph style)
    * `KapsoEx.WhatsApp.PhoneNumbers` - phone number details and settings
    * `KapsoEx.WhatsApp.BusinessProfile` - business profile
    * `KapsoEx.WhatsApp.BlockUsers` - block and unblock users
    * `KapsoEx.WhatsApp.Usernames` - business usernames
    * `KapsoEx.WhatsApp.ConversionEvents` - Conversions API datasets and events
  """

  @doc """
  Builds a value for the `fields` query param that selects Kapso extension
  fields.

  ## Examples

      iex> KapsoEx.WhatsApp.kapso_fields()
      "kapso(default)"

      iex> KapsoEx.WhatsApp.kapso_fields([:media_url, :flow_response])
      "kapso(media_url,flow_response)"

      iex> KapsoEx.WhatsApp.kapso_fields([])
      "kapso()"

  Pass it to any list or get function:

      KapsoEx.WhatsApp.Messages.list(client, phone_number_id, fields: KapsoEx.WhatsApp.kapso_fields([:media_url]))
  """
  @spec kapso_fields(:default | [atom() | String.t()]) :: String.t()
  def kapso_fields(fields \\ :default)
  def kapso_fields(:default), do: "kapso(default)"
  def kapso_fields(fields) when is_list(fields), do: "kapso(#{Enum.join(fields, ",")})"
end
