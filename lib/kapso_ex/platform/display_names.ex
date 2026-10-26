defmodule KapsoEx.Platform.DisplayNames do
  @moduledoc """
  Display name change requests. Meta reviews most changes within 24-48
  hours; poll `get/3` to follow the review.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc "Lists display name requests for a number, most recent first. Params: `page`, `per_page`."
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, phone_number_id, params \\ []) do
    Request.get(client, :platform, path(phone_number_id), query: params)
  end

  @doc "Requests a display name change."
  @spec create(Client.t(), String.t(), String.t()) :: result()
  def create(%Client{} = client, phone_number_id, new_display_name) do
    Request.post(client, :platform, path(phone_number_id),
      json: Request.wrap(%{new_display_name: new_display_name}, :display_name_request)
    )
  end

  @doc "Gets a display name request and its review status."
  @spec get(Client.t(), String.t(), String.t()) :: result()
  def get(%Client{} = client, phone_number_id, request_id) do
    Request.get(client, :platform, path(phone_number_id) ++ [request_id])
  end

  defp path(phone_number_id),
    do: ["whatsapp", "phone_numbers", phone_number_id, "display_name_requests"]
end
