defmodule Yookassa.WebhookHandler do
  @moduledoc """
  A Plug router for processing incoming webhook notifications from YooKassa.

  This module provides a pre-built handler that can parse and react to various
  payment and refund events sent by YooKassa. By default, it simply logs the
  event information to the console, but it is designed to be extended or used as
  a template for your own business logic.

  ## Integration

  This handler is a standard Plug and does **not** start its own web server.
  You are responsible for integrating it into your application's supervision tree
  with a web server like `Plug.Cowboy` or into your Phoenix application's router.

  ### Example with Plug.Cowboy

  When using `Plug.Cowboy`, this handler will respond to any POST request path that
  matches a route defined inside, like `post "/webhook"`.

  1.  **Add to your `application.ex`:**
      ```elixir
      children = [
        {Plug.Cowboy, scheme: :http, plug: Yookassa.WebhookHandler, options: [port: 8080]}
      ]
      ```
  2.  **Configure YooKassa Webhook URL:**
      `https://your-ngrok-or-domain.com/webhook`

  ### Example with Phoenix Router

  In Phoenix, you define the path explicitly.

  1.  **Add to your `router.ex`:**
      ```elixir
      # lib/my_app_web/router.ex
      post "/yookassa_notifications", to: Yookassa.WebhookHandler
      ```
  2.  **Configure YooKassa Webhook URL:**
      `https://your-domain.com/yookassa_notifications`

  ## Supported Events

  This handler can parse and log the following events:
    - `payment.succeeded`
    - `payment.canceled`
    - `payment.waiting_for_capture`
    - `refund.succeeded`
  """

  # Use Plug.Router for simple routing
  use Plug.Router

  # Specify which plugs we will use in order
  plug(:match)
  # This plug automatically parses incoming JSON into an Elixir map
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  post "/webhook" do
    # conn.body_params will contain data from YooKassa
    body = conn.body_params

    # Check the event type and extract payment or refund ID
    case body do
      %{"event" => "payment.succeeded", "object" => %{"id" => payment_id, "status" => status}} ->
        IO.puts("===== 🔔 PAYMENT SUCCEEDED! =====")
        IO.puts("Payment ID: #{payment_id}, Status: #{status}")

      %{"event" => "payment.canceled", "object" => %{"id" => payment_id, "status" => status}} ->
        IO.puts("===== ❌ PAYMENT CANCELED! =====")
        IO.puts("Payment ID: #{payment_id}, Status: #{status}")

      %{
        "event" => "payment.waiting_for_capture",
        "object" => %{"id" => payment_id, "status" => status}
      } ->
        IO.puts("===== ⏳ PAYMENT WAITING FOR CAPTURE! =====")
        IO.puts("Payment ID: #{payment_id}, Status: #{status}")

      %{"event" => "payment.pending", "object" => %{"id" => payment_id, "status" => status}} ->
        IO.puts("===== 🕒 PAYMENT PENDING! =====")
        IO.puts("Payment ID: #{payment_id}, Status: #{status}")

      %{
        "event" => "refund.succeeded",
        "object" => %{"id" => refund_id, "status" => status, "payment_id" => payment_id}
      } ->
        IO.puts("===== 💰 REFUND SUCCEEDED! =====")
        IO.puts("Refund ID: #{refund_id}, Payment ID: #{payment_id}, Status: #{status}")

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
