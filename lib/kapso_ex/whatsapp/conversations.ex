defmodule KapsoEx.WhatsApp.Conversations do
  @moduledoc """
  Conversations stored by Kapso for a phone number, plus thread control on
  [shared numbers](https://docs.kapso.ai/docs/whatsapp/conversation-routing).

  For project-wide queries, assignments and status changes see
  `KapsoEx.Platform.Conversations`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists conversations, latest activity first.

  Params: `status` (`"active"`/`"ended"`), `assigned_user_id`, `unassigned`,
  `last_active_since`, `last_active_until`, `phone_number`, `limit`,
  `before`, `after`, `fields`.
  """
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, phone_number_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "conversations"], query: params)
  end

  @doc "Gets a conversation. Params: `fields`."
  @spec get(Client.t(), String.t(), String.t(), map() | keyword()) :: result()
  def get(%Client{} = client, phone_number_id, conversation_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "conversations", conversation_id],
      query: params
    )
  end

  @doc """
  Passes, releases or takes a conversation between apps on a shared number.

  `action` is `"pass"`, `"release"` or `"take"`. `to` is a phone number or a
  map with `:to` / `:recipient`.

  ## Options

    * `:target_role` - for `"pass"`: `"escalation"`, `"ai_agent"`,
      `"customer_service"`, `"marketing"`, `"utility"` or `"ctwa"`.
    * `:metadata` - string (up to 2000 chars) passed to the receiving app.

  A `502` means the outcome is unknown; Kapso never retries it.

      Conversations.thread_control(client, phone_number_id, "15551234567", "pass",
        target_role: "escalation", metadata: "Customer asked for a human")
  """
  @spec thread_control(Client.t(), String.t(), String.t() | map(), String.t(), keyword()) ::
          result()
  def thread_control(%Client{} = client, phone_number_id, to, action, opts \\ []) do
    payload =
      to
      |> recipient()
      |> Map.merge(%{messaging_product: "whatsapp", action: action})
      |> put_present(:control_pass, opts[:target_role] && %{target_role: opts[:target_role]})
      |> put_present(:metadata, opts[:metadata])

    Request.post(client, :whatsapp, [phone_number_id, "thread_control"], json: payload)
  end

  defp recipient(to) when is_binary(to), do: %{to: to}
  defp recipient(to), do: to |> Map.new() |> Map.take([:to, :recipient])

  defp put_present(map, _key, nil), do: map
  defp put_present(map, key, value), do: Map.put(map, key, value)
end
