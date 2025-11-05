defmodule Yookassa.WebhookHandler do
  @moduledoc """
  A Plug router for processing incoming webhook notifications from YooKassa.

  This module provides a pre-built handler that can parse and react to various
  payment and refund events sent by YooKassa. It includes built-in verification
  to ensure the authenticity of notifications by fetching the latest status from
  the YooKassa API and comparing it with the event data.

  ## Security Features

  The handler implements webhook verification by:
  - Extracting only the `id` and `event` from incoming notifications
  - Making authenticated API requests to YooKassa to fetch current payment/refund status
  - Comparing the fetched status with the expected status from the event
  - Only responding with 200 OK if verification succeeds

  This prevents processing of spoofed or outdated webhook notifications.

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

  This handler verifies and processes the following events:
    - `payment.succeeded`
    - `payment.canceled`
    - `payment.waiting_for_capture`
    - `payment.pending`
    - `refund.succeeded`
    - `refund.canceled`

  ## Response Behavior

  - **200 OK**: Sent only when notification verification succeeds
  - **400 Bad Request**: Sent when verification fails or notification format is invalid
  - **404 Not Found**: Sent for requests to unsupported paths
  """

  # Use Plug.Router for simple routing
  use Plug.Router

  alias Yookassa

  # Specify which plugs we will use in order
  plug(:match)
  # This plug automatically parses incoming JSON into an Elixir map
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  post "/webhook" do
    # conn.body_params will contain data from YooKassa
    body = conn.body_params

    # Extract only id and event from the notification
    case body do
      %{"event" => event, "object" => %{"id" => id}} ->
        # Verify the notification by fetching info from YooKassa API
        case verify_notification(event, id) do
          :ok ->
            IO.puts("===== ✅ NOTIFICATION VERIFIED: #{event} =====")
            IO.puts("ID: #{id}")
            send_resp(conn, 200, "OK")

          {:error, reason} ->
            IO.puts("===== ❌ NOTIFICATION VERIFICATION FAILED: #{event} =====")
            IO.puts("ID: #{id}, Reason: #{inspect(reason)}")
            send_resp(conn, 400, "Verification Failed")
        end

      _ ->
        IO.puts("===== ⚠️ UNKNOWN NOTIFICATION FORMAT =====")
        IO.inspect(body)
        send_resp(conn, 400, "Invalid Format")
    end
  end

  # If a request comes to any other address, respond with 404
  match _ do
    send_resp(conn, 404, "Not Found")
  end

  # Private function to verify notification by fetching from API
  defp verify_notification(event, id) do
    case String.split(event, ".") do
      ["payment", status] ->
        # For payment events, fetch payment info
        case Yookassa.get_payment_info(id) do
          {:ok, payment} ->
            # Check if the status matches the event
            if payment.status == status do
              :ok
            else
              {:error, "Status mismatch: expected #{status}, got #{payment.status}"}
            end

          {:error, reason} ->
            {:error, reason}
        end

      ["refund", status] ->
        # For refund events, fetch refund info
        case Yookassa.get_refund_info(id) do
          {:ok, refund} ->
            # Check if the status matches the event
            if refund.status == status do
              :ok
            else
              {:error, "Status mismatch: expected #{status}, got #{refund.status}"}
            end

          {:error, reason} ->
            {:error, reason}
        end

      _ ->
        {:error, "Unknown event type"}
    end
  end
end
