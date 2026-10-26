defmodule KapsoEx.WhatsApp.TemplateComponents do
  @moduledoc """
  Builders for the `components` list sent with a template message.

  Parameter values may be strings (sent as `text` parameters) or full
  parameter maps, such as `%{type: "currency", currency: %{...}}`.

  ## Examples

      alias KapsoEx.WhatsApp.TemplateComponents, as: C

      # Positional parameters ({{1}}, {{2}})
      C.body(["Ana", "#1234"])

      # Named parameters ({{first_name}})
      C.body(first_name: "Ana", order_number: "#1234")

      Messages.send_template(client, phone_number_id, "56961567267", "seasonal_promotion", "en_US",
        components: [
          C.header_media(:image, "https://example.com/sale.jpg"),
          C.body(sale_name: "Summer Sale"),
          C.button_url(0, "summer2024"),
          C.button_quick_reply(1, "unsubscribe")
        ]
      )
  """

  @type value :: String.t() | map()

  @doc """
  Body parameters: a list of values (positional) or a keyword list / map of
  `parameter_name => value` (named).
  """
  @spec body([value()] | keyword() | map()) :: map()
  def body(params), do: %{type: "body", parameters: parameters(params)}

  @doc "Text header with one parameter, optionally named."
  @spec header_text(value()) :: map()
  def header_text(value), do: %{type: "header", parameters: [parameter(value)]}

  @spec header_text(atom() | String.t(), value()) :: map()
  def header_text(name, value), do: %{type: "header", parameters: [named(name, value)]}

  @doc """
  Media header. `type` is `:image`, `:video` or `:document`; `media` is a
  URL, an uploaded media ID or a map such as `%{id: ..., filename: ...}`.
  """
  @spec header_media(:image | :video | :document, String.t() | map()) :: map()
  def header_media(type, media) when type in [:image, :video, :document] do
    %{type: "header", parameters: [%{:type => type, type => media_object(media)}]}
  end

  @doc "Location header with `:latitude`, `:longitude`, `:name` and `:address`."
  @spec header_location(map() | keyword()) :: map()
  def header_location(location) do
    %{type: "header", parameters: [%{type: "location", location: Map.new(location)}]}
  end

  @doc "Dynamic suffix for the URL button at `index`."
  @spec button_url(non_neg_integer(), value()) :: map()
  def button_url(index, value), do: button("url", index, [parameter(value)])

  @doc "Payload returned when the quick reply button at `index` is tapped."
  @spec button_quick_reply(non_neg_integer(), String.t()) :: map()
  def button_quick_reply(index, payload),
    do: button("quick_reply", index, [%{type: "payload", payload: payload}])

  @doc "Coupon code for the copy code button at `index`."
  @spec button_copy_code(non_neg_integer(), String.t()) :: map()
  def button_copy_code(index, code),
    do: button("copy_code", index, [%{type: "coupon_code", coupon_code: code}])

  @doc """
  Action for the flow button at `index`, such as
  `%{flow_token: "...", flow_action_data: %{...}}`.
  """
  @spec button_flow(non_neg_integer(), map()) :: map()
  def button_flow(index, action), do: button("flow", index, [%{type: "action", action: action}])

  @doc """
  Components for an authentication (OTP) template: the code in the body and
  in the copy code / one-tap button.

      Messages.send_template(client, phone_number_id, "56961567267", "login_code", "es",
        components: TemplateComponents.authentication("482913"))
  """
  @spec authentication(String.t()) :: [map()]
  def authentication(code), do: [body([code]), button_url(0, code)]

  defp button(sub_type, index, parameters),
    do: %{type: "button", sub_type: sub_type, index: to_string(index), parameters: parameters}

  defp parameters(%{} = params), do: Enum.map(params, fn {name, value} -> named(name, value) end)

  defp parameters(params) when is_list(params) do
    if params != [] and Keyword.keyword?(params) do
      Enum.map(params, fn {name, value} -> named(name, value) end)
    else
      Enum.map(params, &parameter/1)
    end
  end

  defp named(name, value), do: Map.put(parameter(value), :parameter_name, to_string(name))

  defp parameter(value) when is_binary(value), do: %{type: "text", text: value}
  defp parameter(%{} = value), do: value

  defp media_object("http://" <> _ = url), do: %{link: url}
  defp media_object("https://" <> _ = url), do: %{link: url}
  defp media_object(id) when is_binary(id), do: %{id: id}
  defp media_object(%{} = media), do: media
end
