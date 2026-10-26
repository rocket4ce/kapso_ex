defmodule KapsoEx.WhatsApp.Usernames do
  @moduledoc """
  [Business usernames](https://docs.kapso.ai/docs/whatsapp/business-usernames)
  for a phone number.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc "Gets the current username and its status (`\"approved\"` or `\"reserved\"`)."
  @spec get(Client.t(), String.t()) :: result()
  def get(%Client{} = client, phone_number_id) do
    Request.get(client, :whatsapp, [phone_number_id, "username"])
  end

  @doc """
  Claims or changes the username.

  ## Options

    * `:transfer_action` - `"none"` (default) or `"force_transfer"` to take
      a username already used by another number in the same portfolio.
  """
  @spec set(Client.t(), String.t(), String.t(), keyword()) :: result()
  def set(%Client{} = client, phone_number_id, username, opts \\ []) do
    payload =
      opts |> Keyword.take([:transfer_action]) |> Map.new() |> Map.put(:username, username)

    Request.post(client, :whatsapp, [phone_number_id, "username"], json: payload)
  end

  @doc "Deletes the username."
  @spec delete(Client.t(), String.t()) :: result()
  def delete(%Client{} = client, phone_number_id) do
    Request.delete(client, :whatsapp, [phone_number_id, "username"])
  end

  @doc "Gets reserved username suggestions."
  @spec suggestions(Client.t(), String.t()) :: result()
  def suggestions(%Client{} = client, phone_number_id) do
    Request.get(client, :whatsapp, [phone_number_id, "username_suggestions"])
  end
end
