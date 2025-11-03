defmodule Yookassa.WebhookHandler do
  @moduledoc """
  Webhook handler for processing YooKassa notifications.

  This module implements a Plug-based web server that listens for webhook notifications
  from YooKassa. It handles various payment and refund events, logging them to the console.
  The handler responds with HTTP 200 OK to acknowledge receipt of notifications.

  ## Supported Events

  The handler processes the following webhook events:

    - `payment.succeeded`: Payment completed successfully
    - `payment.canceled`: Payment was canceled
    - `payment.waiting_for_capture`: Payment is waiting for capture (two-stage payments)
    - `payment.pending`: Payment is pending processing
    - `refund.succeeded`: Refund completed successfully
    - `refund.canceled`: Refund was canceled

  ## Configuration

  The webhook endpoint is available at `/webhook` and expects POST requests with JSON payloads
  containing the event data. The server runs on port 4000 by default.

  ## Usage

  This module is automatically started as part of the application supervision tree.
  Webhook notifications are logged to the console for monitoring and debugging purposes.
  In a production environment, you would typically replace the IO.puts calls with proper
  business logic to handle each event type.
  """

  # Use Plug.Router for simple routing
  use Plug.Router

  # Specify which plugs we will use in order
  plug(:match)
  # This plug automatically parses incoming JSON into an Elixir map
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  # Listen for POST requests at /webhook
  # Handles POST requests to the /webhook endpoint.
  #
  # This function processes webhook notifications from YooKassa, logging different
  # types of payment and refund events to the console. It responds with HTTP 200 OK
  # to acknowledge receipt of the notification.
  #
  # ## Parameters
  #
  #   - `conn`: The Plug connection containing the webhook payload
  #
  # ## Supported Events
  #
  # The handler recognizes and logs the following events:
  # - `payment.succeeded`: Successful payment completion
  # - `payment.canceled`: Payment cancellation
  # - `payment.waiting_for_capture`: Payment awaiting capture (two-stage)
  # - `payment.pending`: Payment in pending state
  # - `refund.succeeded`: Successful refund completion
  # - `refund.canceled`: Refund cancellation with details
  #
  # ## Response
  #
  # Always returns HTTP 200 OK with "OK" body to acknowledge the webhook.
  post "/webhook" do
    # conn.body_params will contain data from YooKassa
    body = conn.body_params

    # Check the event type and extract payment or refund ID
    case body do
      %{"event" => "payment.succeeded", "object" => %{"id" => payment_id, "status" => status}} ->
        IO.puts("===== 🔔 PAYMENT SUCCEEDED! =====")
        IO.puts("Payment ID: #{payment_id}, Status: #{status}")

      # Handle successful payment (final status)

      %{"event" => "payment.canceled", "object" => %{"id" => payment_id, "status" => status}} ->
        IO.puts("===== ❌ PAYMENT CANCELED! =====")
        IO.puts("Payment ID: #{payment_id}, Status: #{status}")

      # Handle canceled payment (final status)

      %{
        "event" => "payment.waiting_for_capture",
        "object" => %{"id" => payment_id, "status" => status}
      } ->
        IO.puts("===== ⏳ PAYMENT WAITING FOR CAPTURE! =====")
        IO.puts("Payment ID: #{payment_id}, Status: #{status}")

      # Handle payment waiting for capture (two-stage payment)

      %{"event" => "payment.pending", "object" => %{"id" => payment_id, "status" => status}} ->
        IO.puts("===== 🕒 PAYMENT PENDING! =====")
        IO.puts("Payment ID: #{payment_id}, Status: #{status}")

      # Handle pending payment (can transition to succeeded, waiting_for_capture, or canceled)

      %{
        "event" => "refund.succeeded",
        "object" => %{"id" => refund_id, "status" => status, "payment_id" => payment_id}
      } ->
        IO.puts("===== 💰 REFUND SUCCEEDED! =====")
        IO.puts("Refund ID: #{refund_id}, Payment ID: #{payment_id}, Status: #{status}")

      # Handle successful refund

      %{
        "event" => "refund.canceled",
        "object" => %{
          "id" => refund_id,
          "status" => status,
          "payment_id" => payment_id,
          "cancellation_details" => cancellation_details
        }
      } ->
        IO.puts("===== 🚫 REFUND CANCELED! =====")
        IO.puts("Refund ID: #{refund_id}, Payment ID: #{payment_id}, Status: #{status}")
        IO.inspect(cancellation_details)

      # Handle canceled refund with cancellation details

      %{"event" => event, "object" => %{"id" => id, "status" => status}} ->
        IO.puts("===== ℹ️ NOTIFICATION RECEIVED: #{event} =====")
        IO.puts("ID: #{id}, Status: #{status}")

      _ ->
        IO.puts("===== ⚠️ UNKNOWN NOTIFICATION FORMAT =====")
        IO.inspect(body)
    end

    # YooKassa requires us to respond with 200 OK status
    # so it understands that the notification was delivered.
    send_resp(conn, 200, "OK")
  end

  # If a request comes to any other address, respond with 404
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
