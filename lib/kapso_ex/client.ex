defmodule KapsoEx.Client do
  @moduledoc """
  Holds the credentials and HTTP settings used for every request.

  Build one with `KapsoEx.new/1` and pass it as the first argument to any
  resource function. A client is a plain struct, so it is cheap to create one
  per Kapso project (for example, one per customer when you are a Tech
  Provider).

  ## Fields

    * `:api_key` - Kapso project API key, sent as `X-API-Key`. Required for
      the Platform, Workflows and Kapso Agent APIs.

    * `:access_token` - optional bearer token for the WhatsApp API. When set,
      WhatsApp requests send `Authorization: Bearer <token>` instead of
      `X-API-Key`. Combined with `:whatsapp_base_url`, this lets you call
      Meta's Graph API directly.

    * `:whatsapp_base_url` - defaults to `"https://api.kapso.ai/meta/whatsapp/v24.0"`.

    * `:platform_base_url` - defaults to `"https://api.kapso.ai/platform/v1"`.
      Also used by the Workflows, Functions and Kapso Agent modules.

    * `:req_options` - extra options merged into every `Req` request, such as
      `:receive_timeout`, `:retry` or `:plug` (for `Req.Test` stubs).
  """

  @whatsapp_base_url "https://api.kapso.ai/meta/whatsapp/v24.0"
  @platform_base_url "https://api.kapso.ai/platform/v1"

  @derive {Inspect, except: [:api_key, :access_token]}
  defstruct api_key: nil,
            access_token: nil,
            whatsapp_base_url: @whatsapp_base_url,
            platform_base_url: @platform_base_url,
            req_options: []

  @type t :: %__MODULE__{
          api_key: String.t() | nil,
          access_token: String.t() | nil,
          whatsapp_base_url: String.t(),
          platform_base_url: String.t(),
          req_options: keyword()
        }

  @keys [:api_key, :access_token, :whatsapp_base_url, :platform_base_url, :req_options]

  @doc """
  Builds a client from `opts`, falling back to the `:kapso_ex` application
  environment for any option that is not given.

  Raises `ArgumentError` when neither `:api_key` nor `:access_token` is set.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    opts =
      :kapso_ex
      |> Application.get_all_env()
      |> Keyword.take(@keys)
      |> Keyword.merge(opts)
      |> Keyword.validate!(@keys)

    client = struct!(__MODULE__, opts)

    if is_nil(client.api_key) and is_nil(client.access_token) do
      raise ArgumentError,
            "KapsoEx requires an :api_key (or an :access_token for the WhatsApp API). " <>
              "Pass it to KapsoEx.new/1 or set `config :kapso_ex, api_key: ...`"
    end

    client
  end
end
