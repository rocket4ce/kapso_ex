defmodule KapsoEx.WhatsApp.BlockUsers do
  @moduledoc """
  Block users from messaging a phone number, and unblock them.

  Users are identified by phone number (`"+56961567267"`) or WhatsApp ID.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc "Lists blocked users."
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, phone_number_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "block_users"], query: params)
  end

  @doc "Blocks one or more users."
  @spec block(Client.t(), String.t(), [String.t()]) :: result()
  def block(%Client{} = client, phone_number_id, users) when is_list(users) do
    Request.post(client, :whatsapp, [phone_number_id, "block_users"], json: payload(users))
  end

  @doc "Unblocks one or more users."
  @spec unblock(Client.t(), String.t(), [String.t()]) :: result()
  def unblock(%Client{} = client, phone_number_id, users) when is_list(users) do
    Request.delete(client, :whatsapp, [phone_number_id, "block_users"], json: payload(users))
  end

  defp payload(users) do
    %{messaging_product: "whatsapp", block_users: Enum.map(users, &%{user: &1})}
  end
end
