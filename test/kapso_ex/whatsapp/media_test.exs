defmodule KapsoEx.WhatsApp.MediaTest do
  use ExUnit.Case, async: true

  import KapsoEx.TestHelpers

  alias KapsoEx.WhatsApp.Media

  @moduletag :tmp_dir

  test "upload/4 sends a multipart body with the file and its type" do
    capture(%{"id" => "media_1"})

    assert {:ok, %{"id" => "media_1"}} =
             Media.upload(client(), "123", "PNGDATA", filename: "photo.png")

    assert_received {:request,
                     %{
                       method: "POST",
                       path: "/meta/whatsapp/v24.0/123/media",
                       headers: headers,
                       body: body
                     }}

    assert headers["content-type"] =~ "multipart/form-data"
    assert body =~ ~s(name="messaging_product"\r\n\r\nwhatsapp)
    assert body =~ ~s(name="type"\r\n\r\nimage/png)
    assert body =~ ~s(name="file"; filename="photo.png")
    assert body =~ "content-type: image/png"
    assert body =~ "PNGDATA"
  end

  test "upload_file/4 reads the file and uses its basename", %{tmp_dir: tmp_dir} do
    capture(%{"id" => "media_2"})
    path = Path.join(tmp_dir, "report.pdf")
    File.write!(path, "%PDF")

    assert {:ok, %{"id" => "media_2"}} = Media.upload_file(client(), "123", path)

    assert_received {:request, %{body: body}}
    assert body =~ ~s(filename="report.pdf")
    assert body =~ "content-type: application/pdf"
  end

  test "download/3 fetches the signed download_url without the API key" do
    download_url = "https://api.kapso.ai/meta/whatsapp/v24.0/media_download?token=signed"

    Req.Test.stub(KapsoEx, fn conn ->
      case conn.request_path do
        "/meta/whatsapp/v24.0/media_1" ->
          Req.Test.json(conn, %{"id" => "media_1", "download_url" => download_url})

        "/meta/whatsapp/v24.0/media_download" ->
          assert conn.query_string == "token=signed"
          assert Plug.Conn.get_req_header(conn, "x-api-key") == []

          conn
          |> Plug.Conn.put_resp_content_type("image/jpeg")
          |> Plug.Conn.send_resp(200, <<255, 216, 255>>)
      end
    end)

    assert {:ok, <<255, 216, 255>>} = Media.download(client(), "media_1", "123")
  end

  test "download/3 returns an error when there is no download_url" do
    capture(%{"id" => "media_1", "url" => "https://lookaside.fbsbx.com/x"})

    assert {:error, %KapsoEx.Error{message: "media metadata has no download_url"}} =
             Media.download(client(), "media_1", "123")
  end
end
