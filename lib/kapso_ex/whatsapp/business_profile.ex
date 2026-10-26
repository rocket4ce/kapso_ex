defmodule KapsoEx.WhatsApp.BusinessProfile do
  @moduledoc """
  The business profile users see when they tap your business name in
  WhatsApp.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Gets the business profile. Params: `fields`, for example
  `"about,address,description,email,profile_picture_url,websites,vertical"`.
  """
  @spec get(Client.t(), String.t(), map() | keyword()) :: result()
  def get(%Client{} = client, phone_number_id, params \\ []) do
    Request.get(client, :whatsapp, [phone_number_id, "whatsapp_business_profile"], query: params)
  end

  @doc """
  Updates the business profile. Attributes: `about`, `address`,
  `description`, `email`, `profile_picture_handle`, `vertical`, `websites`.

      BusinessProfile.update(client, phone_number_id, %{about: "Open 9-18", websites: ["https://acme.cl"]})
  """
  @spec update(Client.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, phone_number_id, attrs) do
    payload = attrs |> Request.to_map() |> Map.put_new(:messaging_product, "whatsapp")
    Request.post(client, :whatsapp, [phone_number_id, "whatsapp_business_profile"], json: payload)
  end
end
