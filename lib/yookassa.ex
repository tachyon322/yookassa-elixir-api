defmodule Yookassa do
  @moduledoc """
  Main module for working with YooKassa API.

  This module provides high-level functions for creating payments, handling captures,
  cancellations, and refunds through the YooKassa payment processing service.
  It serves as the primary interface for integrating YooKassa payments into your application.

  ## Configuration

  Before using this module, ensure you have configured the following in your `config.exs`:

      config :yookassa,
        api_url: "https://api.yookassa.ru/v3",
        shop_id: "your_shop_id",
        secret_key: "your_secret_key"

  ## Usage

  The module provides functions for the complete payment lifecycle:

  - Create payments with `create_payment/5`
  - Capture authorized payments with `capture_payment/2`
  - Cancel payments with `cancel_payment/1`
  - Create refunds with `create_refund/3`
  - Retrieve payment/refund info with `get_payment_info/1` and `get_refund_info/1`

  ## Error Handling

  All functions return `{:ok, result}` on success or `{:error, details}` on failure.
  Error details include HTTP status codes and error messages from the YooKassa API.
  """

  alias Yookassa.Client

  @doc """
  Creates a new payment with explicitly specified parameters.

  ## Parameters

    - `value`: Payment amount as a string (e.g., "100.00") or number.
    - `currency`: Three-letter currency code (e.g., "RUB").
    - `return_url`: URL where the user will return after payment.
    - `description`: Order description that the user will see.
    - `opts`: List of optional parameters, such as `capture: true`, `metadata: %{...}`.

  ## Example call

      Yookassa.create_payment("199.50", "RUB", "https://example.com/thanks", "Order №72", capture: true)

  """
  def create_payment(value, currency, return_url, description, opts \\ []) do
    # 1. Assemble the basic request structure from required arguments
    base_params = %{
      "amount" => %{
        # to_string for universality
        "value" => to_string(value),
        "currency" => currency
      },
      "confirmation" => %{
        "type" => "redirect",
        "return_url" => return_url
      },
      "description" => description,
      "capture" => true
    }

    # 2. Convert the options list to a map and add to base parameters.
    #    Map.new() converts [capture: true] to %{"capture" => true}
    #    Map.merge() overlays options on top of base parameters.
    #    If opts contains "description", it will overwrite the base one.
    final_params = Map.merge(base_params, Map.new(opts))

    # 3. Call our client with the final set of parameters
    with {:ok, response} <- Client.post("/payments", final_params),
         %Req.Response{status: 200, body: body} <- response do
      {:ok, body}
    else
      {:error, %Req.Response{status: status, body: body}} ->
        {:error, %{status: status, reason: body}}

      error ->
        {:error, %{reason: "Unknown error", details: error}}
    end
  end

  @doc """
  Confirms the capture of a previously authorized amount (for two-stage payments).

  If the payment was created with `capture: false`, this function initiates the actual
  debiting of money from the user's account.

  ## Parameters
    - `payment_id`: Payment ID in `waiting_for_capture` status.
    - `opts`: Optional options. You can pass `amount: %{...}` for partial capture.
      If no options are passed, the full payment amount is captured.

  ## Example
      # Capture the full amount
      Yookassa.capture_payment("21740069-...")

      # Capture a partial amount
      amount_to_capture = %{"value" => "50.00", "currency" => "RUB"}
      Yookassa.capture_payment("21740069-...", amount: amount_to_capture)
  """
  def capture_payment(payment_id, opts \\ []) do
    # YooKassa API requires passing a request body, even if it's empty
    body = Keyword.get(opts, :amount, %{})

    with {:ok, response} <- Client.post("/payments/#{payment_id}/capture", body),
         %Req.Response{status: 200, body: body} <- response do
      {:ok, body}
    else
      {:error, %Req.Response{status: status, body: body}} ->
        {:error, %{status: status, reason: body}}

      error ->
        {:error, %{reason: "Unknown error", details: error}}
    end
  end

  @doc """
  Cancels a payment waiting for capture (in `waiting_for_capture` status).

  Funds blocked on the user's card will be unblocked.
  This is not a refund, as no capture has occurred yet.

  ## Parameters
    - `payment_id`: Payment ID in `waiting_for_capture` status.

  ## Example

      Yookassa.cancel_payment("21740069-...")
  """
  def cancel_payment(payment_id) do
    # Request body for cancellation is always empty
    with {:ok, response} <- Client.post("/payments/#{payment_id}/cancel", %{}),
         %Req.Response{status: 200, body: body} <- response do
      {:ok, body}
    else
      {:error, %Req.Response{status: status, body: body}} ->
        {:error, %{status: status, reason: body}}

      error ->
        {:error, %{reason: "Unknown error", details: error}}
    end
  end

  @doc """
  Gets information about a specific payment by its ID.
  Returns a Payment struct.

  ## Example

      Yookassa.get_payment_info("21740069-...")
  """
  def get_payment_info(payment_id) do
    # We use Client, but now for a GET request
    with {:ok, response} <- Yookassa.Client.get("/payments/#{payment_id}"),
         %Req.Response{status: 200, body: body} <- response do
      {:ok, Yookassa.Payment.from_map(body)}
    else
      {:error, %Req.Response{status: status, body: body}} ->
        {:error, %{status: status, reason: body}}

      error ->
        {:error, %{reason: "Unknown error", details: error}}
    end
  end

  @doc """
  Creates a payment refund.

  ## Parameters

    - `payment_id`: Payment ID for which the refund is being created.
    - `value`: Refund amount as a string (e.g., "100.00") or number.
    - `currency`: Three-letter currency code (e.g., "RUB").

  ## Example call

      Yookassa.create_refund("21740069-000f-50be-b000-0486ffbf45b0", "2.00", "RUB")

  """
  def create_refund(payment_id, value, currency) do
    params = %{
      "amount" => %{
        "value" => to_string(value),
        "currency" => currency
      },
      "payment_id" => payment_id
    }

    with {:ok, response} <- Client.post("/refunds", params),
         %Req.Response{status: 200, body: body} <- response do
      {:ok, body}
    else
      {:error, %Req.Response{status: status, body: body}} ->
        {:error, %{status: status, reason: body}}

      error ->
        {:error, %{reason: "Unknown error", details: error}}
    end
  end

  @doc """
  Gets information about a specific refund by its ID.
  Returns a Refund struct.

  ## Example

      Yookassa.get_refund_info("rfnd_1234567890")
  """
  def get_refund_info(refund_id) do
    with {:ok, response} <- Yookassa.Client.get("/refunds/#{refund_id}"),
         %Req.Response{status: 200, body: body} <- response do
      {:ok, Yookassa.Refund.from_map(body)}
    else
      {:error, %Req.Response{status: status, body: body}} ->
        {:error, %{status: status, reason: body}}

      error ->
        {:error, %{reason: "Unknown error", details: error}}
    end
  end
end
