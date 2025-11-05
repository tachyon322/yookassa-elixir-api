defmodule Yookassa do
  @moduledoc """
  The main module for interacting with the YooKassa API.

  This module offers high-level functions for creating payments, capturing funds,
  canceling payments, and processing refunds. It serves as the primary entry point
  for integrating YooKassa functionality into an Elixir application.

  ## Configuration

  Before using the library, configure your credentials in `config/config.exs`:

      config :yookassa,
        shop_id: "your_dev_shop_id",
        secret_key: "your_dev_secret_key",
        api_url: "https://api.yookassa.ru/v3"

  The `:shop_id` and `:secret_key` are required for authentication.

  ## Idempotency

  All `POST` requests automatically include an `Idempotence-Key` header with a unique
  UUIDv4 value. This prevents accidental duplicate operations, ensuring that if a
  request is sent multiple times, it is processed only once.

  ## Usage

  - Create payments with `create_payment/5`
  - Capture authorized payments with `capture_payment/2`
  - Cancel payments with `cancel_payment/1`
  - Create refunds with `create_refund/3`
  - Retrieve payment/refund info with `get_payment_info/1` and `get_refund_info/1`

  ## Error Handling

  All functions return `{:ok, response_body}` on success or `{:error, reason}` on failure.
  The `response_body` is the decoded JSON from the YooKassa API. The `reason` is typically
  a map containing the HTTP status and error details.
  """

  alias Yookassa.Client

  @doc """
  Creates a new payment.

  This function constructs and sends a request to create a new payment with the
  specified amount, currency, and confirmation details. By default, payments are
  created with `capture` set to `true`.

  ## Parameters

    - `value`: The payment amount, provided as a string or number (e.g., "100.00" or 100).
    - `currency`: The three-letter currency code (e.g., "RUB").
    - `return_url`: The URL to redirect the user to after payment confirmation.
    - `description`: A short description of the payment shown to the user.
    - `opts`: A keyword list of optional parameters, such as `:capture` or `:metadata`.

  ## Examples

      # Create a standard one-stage payment
      Yookassa.create_payment("199.50", "RUB", "https://example.com/thanks", "Order №72")

      # Create a two-stage payment (authorize only)
      Yookassa.create_payment("199.50", "RUB", "https://example.com/thanks", "Order №72", capture: false)
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
    user_opts = for {key, val} <- opts, into: %{}, do: {to_string(key), val}

    final_params = Map.merge(base_params, user_opts)

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
  Captures a payment that is in `waiting_for_capture` status.

  This function sends a request to capture the full amount or a specified partial amount
  of an authorized payment. If no amount is provided, the full authorized amount is captured.

  ## Parameters

    - `payment_id`: The ID of the payment to capture.
    - `opts`: A keyword list of optional parameters, such as `:amount` for partial capture.

  ## Examples

      # Capture the full amount of a payment
      Yookassa.capture_payment("21740069-...")

      # Capture a partial amount
      Yookassa.capture_payment("21740069-...", amount: 100.00)
  """
  def capture_payment(payment_id, opts \\ []) do
    body =
      case Keyword.get(opts, :amount) do
        nil ->
          %{}

        amount_value when is_integer(amount_value) ->
          # Handle integer amounts
          amount_map = %{
            "value" => "#{amount_value}.00",
            "currency" => "RUB"
          }

          %{"amount" => amount_map}

        amount_value when is_float(amount_value) ->
          # Handle float amounts
          amount_map = %{
            "value" => :erlang.float_to_binary(amount_value, decimals: 2),
            "currency" => "RUB"
          }

          %{"amount" => amount_map}

        amount_map when is_map(amount_map) ->
          %{"amount" => amount_map}

        _ ->
          IO.warn("Invalid `:amount` option in capture_payment/2. Capturing full amount.")
          %{}
      end

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
  Cancels a payment that is in `waiting_for_capture` status.

  This action releases the hold on the user's funds. It is not a refund, as
  the funds were never captured.

  ## Parameters
    - `payment_id`: The ID of the payment to be canceled.

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
  Retrieves information about a specific payment.

  Returns a `Yookassa.Payment` struct on success.

  ## Parameters
    - `payment_id`: The ID of the payment to retrieve.

  ## Example

      {:ok, payment} = Yookassa.get_payment_info("21740069-...")
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
  Creates a refund for a successful payment.

  ## Parameters

    - `payment_id`: The ID of the payment to be refunded.
    - `value`: The refund amount, as a string or number.
    - `currency`: The three-letter currency code.

  ## Example

      Yookassa.create_refund("21740069-...", "50.00", "RUB")


  ## Notes

  The YooKassa API has certain business rules for refunds:
  - The decimal separator for the `value` must be a dot (`.`), not a comma.
  - After a partial refund, the remaining amount on the payment must be at least 1 RUB.
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
  Retrieves information about a specific refund.

  Returns a `Yookassa.Refund` struct on success.

  ## Parameters
    - `refund_id`: The ID of the refund to retrieve.

  ## Example

      {:ok, refund} = Yookassa.get_refund_info("rfnd_1234567890")
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
