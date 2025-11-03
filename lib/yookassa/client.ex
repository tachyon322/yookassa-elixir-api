defmodule Yookassa.Client do
  @moduledoc """
  Low-level HTTP client for interacting with the YooKassa API.

  This module handles the HTTP communication with YooKassa's REST API, including
  authentication, request formatting, and response parsing. It provides a simple
  interface for making POST and GET requests to the API endpoints.

  ## Authentication

  The client uses HTTP Basic Authentication with your shop ID and secret key.
  These values are configured at compile time from the application environment.

  ## Idempotency

  POST requests include an idempotency key header to ensure safe retries in case
  of network failures or timeouts.

  ## Usage

  This module is primarily used internally by the `Yookassa` module. Direct usage
  is generally not recommended unless you need to make custom API calls.
  """

  # Load configuration from config.exs at compile time
  @api_url Application.compile_env!(:yookassa, :api_url)
  @shop_id Application.compile_env!(:yookassa, :shop_id)
  @secret_key Application.compile_env!(:yookassa, :secret_key)

  # Create a basic, reusable request instance
  @base_req Req.new(
              base_url: @api_url,
              auth: {:basic, "#{@shop_id}:#{@secret_key}"}
            )

  @doc """
  Sends a POST request to the YooKassa API.

  ## Parameters

    - `path`: API endpoint path (e.g., "/payments", "/refunds")
    - `body`: Request body as a map, will be JSON-encoded automatically

  ## Returns

    - `{:ok, %Req.Response{}}` on successful HTTP response
    - `{:error, exception}` on network or other errors

  ## Notes

  The request includes authentication headers and an idempotency key for safe retries.
  """
  def post(path, body) do
    Req.post(@base_req,
      url: path,
      # `Req` automatically converts the map to JSON and adds the Content-Type header
      json: body,
      # Add idempotence header
      headers: idempotence_header()
    )
  end

  @doc """
  Sends a GET request to the YooKassa API.

  ## Parameters

    - `path`: API endpoint path (e.g., "/payments/123", "/refunds/456")

  ## Returns

    - `{:ok, %Req.Response{}}` on successful HTTP response
    - `{:error, exception}` on network or other errors

  ## Notes

  The request includes authentication headers but no idempotency key since GET
  requests are inherently idempotent.
  """
  def get(path) do
    # GET requests don't need a body or idempotence key
    Req.get(@base_req, url: path)
  end

  @doc false
  # Private function to generate a unique idempotence key
  defp idempotence_header do
    %{"Idempotence-Key" => UUID.uuid4()}
  end
end
