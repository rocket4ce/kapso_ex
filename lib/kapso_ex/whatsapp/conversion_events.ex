defmodule KapsoEx.WhatsApp.ConversionEvents do
  @moduledoc """
  Meta Conversions API for WhatsApp: datasets and conversion events.

  Get or create the WABA dataset first, then send events to its ID. Not
  supported on sandbox numbers.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc "Gets the dataset of a WABA and remembers the association. Params: `fields`."
  @spec get_dataset(Client.t(), String.t(), map() | keyword()) :: result()
  def get_dataset(%Client{} = client, business_account_id, params \\ []) do
    Request.get(client, :whatsapp, [business_account_id, "dataset"], query: params)
  end

  @doc "Creates the dataset of a WABA. Attributes: `dataset_name`."
  @spec create_dataset(Client.t(), String.t(), map() | keyword()) :: result()
  def create_dataset(%Client{} = client, business_account_id, attrs \\ %{}) do
    Request.post(client, :whatsapp, [business_account_id, "dataset"], json: attrs)
  end

  @doc """
  Sends conversion events (Meta Conversions API payloads) to a dataset.

  ## Options

    * `:test_event_code` - send as test events, shown in Events Manager.
  """
  @spec send_events(Client.t(), String.t(), [map()], keyword()) :: result()
  def send_events(%Client{} = client, dataset_id, events, opts \\ []) when is_list(events) do
    payload = opts |> Keyword.take([:test_event_code]) |> Map.new() |> Map.put(:data, events)
    Request.post(client, :whatsapp, [dataset_id, "events"], json: payload)
  end
end
