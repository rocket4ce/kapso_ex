defmodule KapsoEx.WhatsApp.Messages do
  @moduledoc """
  Send WhatsApp messages and read stored message history.

  ## Recipients

  Every `send_*` function takes a `to` argument, which is either:

    * a phone number string, such as `"56961567267"`, or
    * a map or keyword list with `:to` (phone number) and/or `:recipient`
      (a business-scoped user ID, such as `"US.13491208655302741918"`).
      When both are given, Meta delivers to the phone number.

  ## Common options

  Every `send_*` function accepts:

    * `:reply_to` - WhatsApp message ID (`wamid...`) to quote as a reply.
    * `:biz_opaque_callback_data` - string echoed back in status webhooks.
    * `:take_control` - on a [shared number](https://docs.kapso.ai/docs/whatsapp/conversation-routing),
      send even though another app handles the conversation (and take it).
      Only works when Kapso is your escalation app.

  ## Media

  Media arguments accept a URL (sent as `link`), a media ID returned by
  `KapsoEx.WhatsApp.Media.upload/4` (sent as `id`), or a map with Meta's
  fields (`%{id: ..., caption: ...}`).

  ## Responses

  Sends return Meta's response:

      {:ok, %{"messaging_product" => "whatsapp",
              "contacts" => [%{"input" => "56961567267", "wa_id" => "56961567267"}],
              "messages" => [%{"id" => "wamid.HBgL..."}]}}
  """

  alias KapsoEx.{Client, Request}

  @type phone_number_id :: String.t()
  @type to ::
          String.t()
          | %{optional(:to) => String.t(), optional(:recipient) => String.t()}
          | keyword()
  @type media :: String.t() | map()
  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Sends a raw message payload, as documented by Meta.

  `messaging_product: "whatsapp"` is added when missing. Use this for message
  types without a dedicated helper. Accepts the `:take_control` option.

      Messages.send(client, phone_number_id, %{
        to: "56961567267",
        type: "interactive",
        interactive: %{type: "product", body: %{text: "Look"}, action: %{catalog_id: "1", product_retailer_id: "sku"}}
      })
  """
  @spec send(Client.t(), phone_number_id(), map() | keyword(), keyword()) :: result()
  def send(%Client{} = client, phone_number_id, payload, opts \\ []) do
    payload = payload |> Request.to_map() |> put_messaging_product()
    headers = if opts[:take_control], do: [{"x-kapso-take-control", "true"}], else: []

    Request.post(client, :whatsapp, [phone_number_id, "messages"],
      json: payload,
      headers: headers
    )
  end

  @doc """
  Sends a text message.

  ## Options

    * `:preview_url` - render a preview for the first URL in `body`.

  Plus the common options in the module docs.
  """
  @spec send_text(Client.t(), phone_number_id(), to(), String.t(), keyword()) :: result()
  def send_text(client, phone_number_id, to, body, opts \\ []) do
    text = put_present(%{body: body}, :preview_url, opts[:preview_url])
    deliver(client, phone_number_id, to, :text, text, opts)
  end

  @doc "Sends an image. Options: `:caption`, plus the common options."
  @spec send_image(Client.t(), phone_number_id(), to(), media(), keyword()) :: result()
  def send_image(client, phone_number_id, to, image, opts \\ []) do
    deliver(client, phone_number_id, to, :image, media(image, opts, [:caption]), opts)
  end

  @doc "Sends a video. Options: `:caption`, plus the common options."
  @spec send_video(Client.t(), phone_number_id(), to(), media(), keyword()) :: result()
  def send_video(client, phone_number_id, to, video, opts \\ []) do
    deliver(client, phone_number_id, to, :video, media(video, opts, [:caption]), opts)
  end

  @doc """
  Sends an audio file.

  ## Options

    * `:voice` - send as a voice note (`.ogg` file with the OPUS codec).

  Plus the common options.
  """
  @spec send_audio(Client.t(), phone_number_id(), to(), media(), keyword()) :: result()
  def send_audio(client, phone_number_id, to, audio, opts \\ []) do
    deliver(client, phone_number_id, to, :audio, media(audio, opts, [:voice]), opts)
  end

  @doc "Sends a document. Options: `:caption`, `:filename`, plus the common options."
  @spec send_document(Client.t(), phone_number_id(), to(), media(), keyword()) :: result()
  def send_document(client, phone_number_id, to, document, opts \\ []) do
    deliver(
      client,
      phone_number_id,
      to,
      :document,
      media(document, opts, [:caption, :filename]),
      opts
    )
  end

  @doc "Sends a sticker (`.webp`)."
  @spec send_sticker(Client.t(), phone_number_id(), to(), media(), keyword()) :: result()
  def send_sticker(client, phone_number_id, to, sticker, opts \\ []) do
    deliver(client, phone_number_id, to, :sticker, media(sticker, opts, []), opts)
  end

  @doc """
  Sends a location pin.

      Messages.send_location(client, phone_number_id, "56961567267",
        %{latitude: -33.4489, longitude: -70.6693, name: "Santiago", address: "CL"})
  """
  @spec send_location(Client.t(), phone_number_id(), to(), map() | keyword(), keyword()) ::
          result()
  def send_location(client, phone_number_id, to, location, opts \\ []) do
    deliver(client, phone_number_id, to, :location, Request.to_map(location), opts)
  end

  @doc """
  Sends one or more contact cards.

      Messages.send_contacts(client, phone_number_id, "56961567267", [
        %{name: %{formatted_name: "Ada Lovelace"}, phones: [%{phone: "+44123456789", type: "WORK"}]}
      ])
  """
  @spec send_contacts(Client.t(), phone_number_id(), to(), [map()], keyword()) :: result()
  def send_contacts(client, phone_number_id, to, contacts, opts \\ []) when is_list(contacts) do
    deliver(client, phone_number_id, to, :contacts, contacts, opts)
  end

  @doc "Reacts to `message_id` with `emoji`. Send `\"\"` to remove a reaction."
  @spec send_reaction(Client.t(), phone_number_id(), to(), String.t(), String.t(), keyword()) ::
          result()
  def send_reaction(client, phone_number_id, to, message_id, emoji, opts \\ []) do
    deliver(client, phone_number_id, to, :reaction, %{message_id: message_id, emoji: emoji}, opts)
  end

  @doc """
  Sends an approved template.

  `language` is a language code such as `"es"` or `"en_US"`. Build
  `:components` by hand or with `KapsoEx.WhatsApp.TemplateComponents`.

  ## Options

    * `:components` - list of template components with parameters.

  Plus the common options.

  ## Examples

      Messages.send_template(client, phone_number_id, "56961567267", "order_update", "es",
        components: [
          %{type: "body", parameters: [%{type: "text", text: "Ana"}, %{type: "text", text: "#1234"}]}
        ]
      )
  """
  @spec send_template(Client.t(), phone_number_id(), to(), String.t(), String.t(), keyword()) ::
          result()
  def send_template(client, phone_number_id, to, name, language, opts \\ []) do
    deliver(client, phone_number_id, to, :template, template(name, language, opts), opts)
  end

  @doc """
  Sends a marketing template through Meta's Marketing Messages API
  (`POST /{phone_number_id}/marketing_messages`).

  Takes the same arguments and options as `send_template/6`.
  """
  @spec send_marketing_template(
          Client.t(),
          phone_number_id(),
          to(),
          String.t(),
          String.t(),
          keyword()
        ) ::
          result()
  def send_marketing_template(client, phone_number_id, to, name, language, opts \\ []) do
    payload = build(to, :template, template(name, language, opts), opts)
    Request.post(client, :whatsapp, [phone_number_id, "marketing_messages"], json: payload)
  end

  @doc """
  Sends an interactive message with a raw `interactive` object, for types
  without a dedicated helper (product, product list, catalog, carousel,
  address, call permission request, voice call, ...).
  """
  @spec send_interactive(Client.t(), phone_number_id(), to(), map() | keyword(), keyword()) ::
          result()
  def send_interactive(client, phone_number_id, to, interactive, opts \\ []) do
    deliver(client, phone_number_id, to, :interactive, Request.to_map(interactive), opts)
  end

  @doc """
  Sends up to three reply buttons.

  `buttons` is a list of `{id, title}` tuples or of full button maps.

  ## Options

    * `:header` - a string (text header) or a header map (image, video, document).
    * `:footer` - footer text.

  Plus the common options.

  ## Examples

      Messages.send_buttons(client, phone_number_id, "56961567267", "Confirm your order?",
        [{"yes", "Yes"}, {"no", "No"}], footer: "Reply within 24h")
  """
  @spec send_buttons(
          Client.t(),
          phone_number_id(),
          to(),
          String.t(),
          [{String.t(), String.t()} | map()],
          keyword()
        ) ::
          result()
  def send_buttons(client, phone_number_id, to, body, buttons, opts \\ []) do
    buttons =
      Enum.map(buttons, fn
        {id, title} -> %{type: "reply", reply: %{id: id, title: title}}
        %{} = button -> button
      end)

    interactive(client, phone_number_id, to, "button", body, %{buttons: buttons}, opts)
  end

  @doc """
  Sends a list picker.

  `sections` is a list of `%{title: ..., rows: [%{id: ..., title: ..., description: ...}]}`
  (up to 10 rows in total). `button` is the label of the button that opens
  the list.

  Options: `:header`, `:footer`, plus the common options.
  """
  @spec send_list(Client.t(), phone_number_id(), to(), String.t(), String.t(), [map()], keyword()) ::
          result()
  def send_list(client, phone_number_id, to, body, button, sections, opts \\ []) do
    interactive(
      client,
      phone_number_id,
      to,
      "list",
      body,
      %{button: button, sections: sections},
      opts
    )
  end

  @doc """
  Sends a call-to-action button that opens `url`.

  Options: `:header`, `:footer`, plus the common options.
  """
  @spec send_cta_url(
          Client.t(),
          phone_number_id(),
          to(),
          String.t(),
          String.t(),
          String.t(),
          keyword()
        ) ::
          result()
  def send_cta_url(client, phone_number_id, to, body, display_text, url, opts \\ []) do
    action = %{name: "cta_url", parameters: %{display_text: display_text, url: url}}
    interactive(client, phone_number_id, to, "cta_url", body, action, opts)
  end

  @doc """
  Sends a WhatsApp Flow.

  `parameters` are the flow action parameters, such as `:flow_id`,
  `:flow_cta`, `:flow_token`, `:mode`, `:flow_action` and
  `:flow_action_payload`. `flow_message_version` defaults to `"3"`.

  Options: `:header`, `:footer`, plus the common options.

      Messages.send_flow(client, phone_number_id, "56961567267", "Book your appointment",
        %{flow_id: "123456789", flow_cta: "Book now", flow_action: "navigate",
          flow_action_payload: %{screen: "BOOKING"}})
  """
  @spec send_flow(Client.t(), phone_number_id(), to(), String.t(), map() | keyword(), keyword()) ::
          result()
  def send_flow(client, phone_number_id, to, body, parameters, opts \\ []) do
    parameters = Map.merge(%{flow_message_version: "3"}, Request.to_map(parameters))

    interactive(
      client,
      phone_number_id,
      to,
      "flow",
      body,
      %{name: "flow", parameters: parameters},
      opts
    )
  end

  @doc "Asks the user to share their current location."
  @spec send_location_request(Client.t(), phone_number_id(), to(), String.t(), keyword()) ::
          result()
  def send_location_request(client, phone_number_id, to, body, opts \\ []) do
    interactive(
      client,
      phone_number_id,
      to,
      "location_request_message",
      body,
      %{name: "send_location"},
      opts
    )
  end

  @doc """
  Marks an inbound message as read.

  ## Options

    * `:typing_indicator` - when `true`, also shows a typing indicator until
      you reply (or for about 25 seconds).
  """
  @spec mark_read(Client.t(), phone_number_id(), String.t(), keyword()) :: result()
  def mark_read(client, phone_number_id, message_id, opts \\ []) do
    payload = %{messaging_product: "whatsapp", status: "read", message_id: message_id}

    payload =
      if opts[:typing_indicator],
        do: Map.put(payload, :typing_indicator, %{type: "text"}),
        else: payload

    Request.post(client, :whatsapp, [phone_number_id, "messages"], json: payload)
  end

  @doc """
  Lists stored messages for a phone number, newest first.

  ## Params

  `conversation_id`, `direction` (`"inbound"`/`"outbound"`), `status`,
  `since`, `until`, `limit`, `before`, `after` and `fields` (see
  `KapsoEx.WhatsApp.kapso_fields/1`).

  Paginates with cursors under `paging.cursors`; see `KapsoEx.Pagination`.
  """
  @spec list(Client.t(), phone_number_id(), map() | keyword()) :: result()
  def list(client, phone_number_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "messages"], query: params)
  end

  @doc "Gets a stored message by its WhatsApp message ID. Params: `fields`."
  @spec get(Client.t(), phone_number_id(), String.t(), map() | keyword()) :: result()
  def get(client, phone_number_id, message_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "messages", message_id], query: params)
  end

  defp deliver(client, phone_number_id, to, type, content, opts) do
    send(client, phone_number_id, build(to, type, content, opts), opts)
  end

  defp interactive(client, phone_number_id, to, type, body, action, opts) do
    interactive =
      %{type: type, body: %{text: body}, action: action}
      |> put_present(:header, header(opts[:header]))
      |> put_present(:footer, opts[:footer] && %{text: opts[:footer]})

    deliver(client, phone_number_id, to, :interactive, interactive, opts)
  end

  defp build(to, type, content, opts) do
    to
    |> recipient()
    |> Map.merge(%{:messaging_product => "whatsapp", :type => type, type => content})
    |> put_present(:context, opts[:reply_to] && %{message_id: opts[:reply_to]})
    |> put_present(:biz_opaque_callback_data, opts[:biz_opaque_callback_data])
  end

  defp recipient(to) when is_binary(to), do: %{to: to}

  defp recipient(to) when is_map(to) or is_list(to) do
    case to |> Map.new() |> Map.take([:to, :recipient]) do
      empty when map_size(empty) == 0 ->
        raise ArgumentError,
              "expected the recipient to have :to and/or :recipient, got: #{inspect(to)}"

      recipient ->
        recipient
    end
  end

  defp template(name, language, opts) do
    language = if is_binary(language), do: %{code: language}, else: Request.to_map(language)
    put_present(%{name: name, language: language}, :components, opts[:components])
  end

  defp media("http://" <> _ = url, opts, keys), do: media(%{link: url}, opts, keys)
  defp media("https://" <> _ = url, opts, keys), do: media(%{link: url}, opts, keys)
  defp media(id, opts, keys) when is_binary(id), do: media(%{id: id}, opts, keys)

  defp media(media, opts, keys) do
    Enum.reduce(keys, Request.to_map(media), fn key, acc -> put_present(acc, key, opts[key]) end)
  end

  defp header(nil), do: nil
  defp header(text) when is_binary(text), do: %{type: "text", text: text}
  defp header(header), do: Request.to_map(header)

  defp put_messaging_product(%{"messaging_product" => _} = payload), do: payload
  defp put_messaging_product(payload), do: Map.put_new(payload, :messaging_product, "whatsapp")

  defp put_present(map, _key, nil), do: map
  defp put_present(map, key, value), do: Map.put(map, key, value)
end
