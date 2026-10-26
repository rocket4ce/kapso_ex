defmodule KapsoEx.WhatsApp.Media do
  @moduledoc """
  Upload, inspect, delete and download WhatsApp media.

  Size limits set by Meta: images (jpeg, png) 5 MB; video (mp4, 3gp) and
  audio (aac, mp3, ogg, opus) 16 MB; documents 100 MB; stickers (webp)
  100 KB static or 500 KB animated.

  To upload media from a public URL instead of bytes, use
  `KapsoEx.Platform.Media.upload/4`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Uploads `content` (a binary) and returns its media ID.

  ## Options

    * `:filename` - required, for example `"photo.jpg"`.
    * `:content_type` - MIME type; inferred from `:filename` when omitted.

  ## Examples

      {:ok, %{"id" => media_id}} =
        Media.upload(client, phone_number_id, File.read!("photo.jpg"), filename: "photo.jpg")

      Messages.send_image(client, phone_number_id, "56961567267", media_id, caption: "Hi")
  """
  @spec upload(Client.t(), String.t(), iodata(), keyword()) :: result()
  def upload(%Client{} = client, phone_number_id, content, opts) do
    filename = Keyword.fetch!(opts, :filename)
    content_type = opts[:content_type] || MIME.from_path(filename)

    Request.post(client, :whatsapp, [phone_number_id, "media"],
      form_multipart: [
        messaging_product: "whatsapp",
        type: content_type,
        file: {content, filename: filename, content_type: content_type}
      ]
    )
  end

  @doc """
  Uploads the file at `path`. Options: `:filename` (defaults to the file's
  basename) and `:content_type`.
  """
  @spec upload_file(Client.t(), String.t(), Path.t(), keyword()) :: result()
  def upload_file(%Client{} = client, phone_number_id, path, opts \\ []) do
    opts = Keyword.put_new(opts, :filename, Path.basename(path))
    upload(client, phone_number_id, File.read!(path), opts)
  end

  @doc """
  Gets media metadata, including a `url` and a short-lived `download_url`
  (valid for about 5 minutes).
  """
  @spec get(Client.t(), String.t(), String.t()) :: result()
  def get(%Client{} = client, media_id, phone_number_id) do
    Request.get(client, :whatsapp, [media_id], query: [phone_number_id: phone_number_id])
  end

  @doc "Deletes an uploaded media file."
  @spec delete(Client.t(), String.t(), String.t()) :: result()
  def delete(%Client{} = client, media_id, phone_number_id) do
    Request.delete(client, :whatsapp, [media_id], query: [phone_number_id: phone_number_id])
  end

  @doc """
  Downloads the bytes of a media file.

  Fetches the metadata with `get/3` and then the signed `download_url`, so
  the media must be known to Kapso (inbound media, or outbound media shortly
  after it was sent).

      {:ok, bytes} = Media.download(client, media_id, phone_number_id)
  """
  @spec download(Client.t(), String.t(), String.t()) ::
          {:ok, binary()} | {:error, KapsoEx.Error.t()}
  def download(%Client{} = client, media_id, phone_number_id) do
    with {:ok, %{"download_url" => url}} when is_binary(url) <-
           get(client, media_id, phone_number_id) do
      Request.fetch_url(client, url)
    else
      {:ok, body} ->
        {:error, %KapsoEx.Error{message: "media metadata has no download_url", body: body}}

      {:error, _} = error ->
        error
    end
  end
end
