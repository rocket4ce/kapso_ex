defmodule KapsoEx.WhatsApp.Calls do
  @moduledoc """
  [WhatsApp Calling](https://docs.kapso.ai/docs/whatsapp/calling/overview):
  call logs, call actions and call permissions.

  Calls are negotiated with WebRTC SDP: you send an SDP offer to start an
  outbound call, and an SDP answer to accept an inbound one (received in the
  call webhook).
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @action_opts [:biz_opaque_callback_data, :recording, :transcription]

  @doc """
  Lists calls. Params: `call_id`, `direction`, `status`, `since`, `until`,
  `limit`, `before`, `after`, `fields`.
  """
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, phone_number_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "calls"], query: params)
  end

  @doc """
  Performs a raw call action. `attrs` needs at least `:action`
  (`"connect"`, `"pre_accept"`, `"accept"`, `"reject"` or `"terminate"`).
  """
  @spec action(Client.t(), String.t(), map() | keyword()) :: result()
  def action(%Client{} = client, phone_number_id, attrs) do
    payload = attrs |> Request.to_map() |> Map.put_new(:messaging_product, "whatsapp")
    Request.post(client, :whatsapp, [phone_number_id, "calls"], json: payload)
  end

  @doc """
  Starts an outbound call to `to` with an SDP offer.

  Check `get_permissions/3` first: the user must have granted permission.

  ## Options

    * `:biz_opaque_callback_data` - echoed back in call webhooks.
    * `:recording` - e.g. `%{status: "ENABLED"}`.
    * `:transcription` - e.g. `%{status: "ENABLED"}`.
  """
  @spec connect(Client.t(), String.t(), String.t(), String.t(), keyword()) :: result()
  def connect(client, phone_number_id, to, sdp_offer, opts \\ []) do
    attrs = %{action: "connect", to: to, session: %{sdp_type: "offer", sdp: sdp_offer}}
    action(client, phone_number_id, Map.merge(attrs, take_opts(opts)))
  end

  @doc "Pre-accepts an inbound call with an SDP answer, to start media setup early."
  @spec pre_accept(Client.t(), String.t(), String.t(), String.t()) :: result()
  def pre_accept(client, phone_number_id, call_id, sdp_answer) do
    attrs = %{
      action: "pre_accept",
      call_id: call_id,
      session: %{sdp_type: "answer", sdp: sdp_answer}
    }

    action(client, phone_number_id, attrs)
  end

  @doc "Accepts an inbound call with an SDP answer. Options as in `connect/5`."
  @spec accept(Client.t(), String.t(), String.t(), String.t(), keyword()) :: result()
  def accept(client, phone_number_id, call_id, sdp_answer, opts \\ []) do
    attrs = %{action: "accept", call_id: call_id, session: %{sdp_type: "answer", sdp: sdp_answer}}
    action(client, phone_number_id, Map.merge(attrs, take_opts(opts)))
  end

  @doc "Rejects an inbound call."
  @spec reject(Client.t(), String.t(), String.t()) :: result()
  def reject(client, phone_number_id, call_id) do
    action(client, phone_number_id, %{action: "reject", call_id: call_id})
  end

  @doc "Ends an ongoing call."
  @spec terminate(Client.t(), String.t(), String.t()) :: result()
  def terminate(client, phone_number_id, call_id) do
    action(client, phone_number_id, %{action: "terminate", call_id: call_id})
  end

  @doc """
  Gets the call permission state with a user. Params: `user_wa_id` (phone
  number) or `recipient` (business-scoped user ID).

  Before dialing, check that `actions` has `start_call` with
  `can_perform_action: true`.
  """
  @spec get_permissions(Client.t(), String.t(), map() | keyword()) :: result()
  def get_permissions(%Client{} = client, phone_number_id, params) do
    Request.get(client, :whatsapp, [phone_number_id, "call_permissions"], query: params)
  end

  defp take_opts(opts), do: opts |> Keyword.take(@action_opts) |> Map.new()
end
