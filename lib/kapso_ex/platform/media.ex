defmodule KapsoEx.Platform.Media do
  @moduledoc """
  Ingest media from a public URL so it can be sent in messages.

  To upload bytes, use `KapsoEx.WhatsApp.Media.upload/4`.
  """

  alias KapsoEx.{Client, Request}

  @doc """
  Fetches `source` (a public URL) and uploads it to Meta for
  `phone_number_id`.

  ## Options

    * `:delivery` - `"meta_media"` (default, returns a media ID for
      messages) or `"meta_resumable_asset"` (returns a handle, for example
      for template headers or profile pictures).
    * `:filename`, `:mime_type` - override what is inferred from the URL.

  ## Examples

      {:ok, %{"data" => %{"target" => %{"media_id" => media_id}}}} =
        Platform.Media.upload(client, phone_number_id, "https://example.com/menu.pdf")
  """
  @spec upload(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, KapsoEx.Error.t()}
  def upload(%Client{} = client, phone_number_id, source, opts \\ []) do
    attrs =
      opts
      |> Keyword.take([:delivery, :filename, :mime_type])
      |> Map.new()
      |> Map.merge(%{phone_number_id: phone_number_id, source: source})

    Request.post(client, :platform, ["whatsapp", "media"],
      json: Request.wrap(attrs, :media_ingest)
    )
  end
end
