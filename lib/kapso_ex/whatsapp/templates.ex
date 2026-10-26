defmodule KapsoEx.WhatsApp.Templates do
  @moduledoc """
  Manage message templates of a WhatsApp Business Account (WABA).

  Templates go through Meta's review; see Kapso's
  [template lifecycle guide](https://docs.kapso.ai/docs/whatsapp/templates/lifecycle).
  To send one, use `KapsoEx.WhatsApp.Messages.send_template/6`.
  """

  alias KapsoEx.{Client, Request}

  @type result :: {:ok, map()} | {:error, KapsoEx.Error.t()}

  @doc """
  Lists templates. Params: `name`, `status`, `category`, `language`, `limit`.
  """
  @spec list(Client.t(), String.t(), map() | keyword()) :: result()
  def list(%Client{} = client, business_account_id, params \\ []) do
    Request.get(client, :whatsapp, [business_account_id, "message_templates"], query: params)
  end

  @doc """
  Creates a template.

      Templates.create(client, waba_id, %{
        name: "order_update",
        language: "es",
        category: "UTILITY",
        parameter_format: "NAMED",
        components: [
          %{type: "BODY", text: "Hola {{first_name}}, tu pedido {{order}} fue enviado.",
            example: %{body_text_named_params: [
              %{param_name: "first_name", example: "Ana"},
              %{param_name: "order", example: "#1234"}
            ]}}
        ]
      })
  """
  @spec create(Client.t(), String.t(), map() | keyword()) :: result()
  def create(%Client{} = client, business_account_id, attrs) do
    Request.post(client, :whatsapp, [business_account_id, "message_templates"], json: attrs)
  end

  @doc "Updates the template with ID `template_id` (Meta's `hsm_id`)."
  @spec update(Client.t(), String.t(), String.t(), map() | keyword()) :: result()
  def update(%Client{} = client, business_account_id, template_id, attrs) do
    Request.post(client, :whatsapp, [business_account_id, "message_templates"],
      query: [hsm_id: template_id],
      json: attrs
    )
  end

  @doc """
  Deletes a template. Pass `name:` to delete every language of a template,
  or `hsm_id:` to delete a single one.

      Templates.delete(client, waba_id, name: "order_update")
  """
  @spec delete(Client.t(), String.t(), map() | keyword()) :: result()
  def delete(%Client{} = client, business_account_id, params) do
    Request.delete(client, :whatsapp, [business_account_id, "message_templates"], query: params)
  end

  @doc "Gets a template by ID. Params: `fields`."
  @spec get(Client.t(), String.t(), String.t(), map() | keyword()) :: result()
  def get(%Client{} = client, business_account_id, template_id, params \\ []) do
    Request.get(client, :whatsapp, [business_account_id, "message_templates", template_id],
      query: params
    )
  end
end
