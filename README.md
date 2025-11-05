# Yookassa Elixir Client

An idiomatic Elixir client for the YooKassa API v3. This library provides a simple and convenient way to integrate YooKassa payment processing into your Elixir applications.

## Features

- Create one-stage and two-stage payments.
- Capture or cancel authorized payments.
- Create full and partial refunds.
- Get details for any payment or refund.
- Includes a ready-to-use Plug for handling webhook notifications.

## Installation

Add `yookassa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:yookassa, "~> 0.1.2"}
  ]
end
```

Then, run `mix deps.get`.

## Configuration

Add the following configuration to your `config/dev.exs` (for development) or `config/releases.exs` (for production). Using environment variables for secrets is highly recommended.

```elixir
# in config/dev.exs
import Config

config :yookassa,
  shop_id: "YOUR_SHOP_ID",
  secret_key: "YOUR_TEST_SECRET_KEY",
  api_url: "https://api.yookassa.ru/v3"

# Recommended for production:
# config :yookassa,
#   shop_id: System.get_env("YOOKASSA_SHOP_ID"),
#   secret_key: System.get_env("YOOKASSA_SECRET_KEY"),
#   api_url: "https://api.yookassa.ru/v3"
```

## Usage

All functions return `{:ok, response_body}` on success or `{:error, reason}` on failure.
The `response_body` is the decoded JSON from the YooKassa API.

### Idempotency

All `POST` requests automatically include an `Idempotence-Key` header with a unique
UUIDv4 value. This prevents accidental duplicate operations, ensuring that if a
request is sent multiple times, it is processed only once.

### Creating a Payment

By default, payments are created with `capture: true` (one-stage).

```elixir
Yookassa.create_payment("199.50", "RUB", "https://example.com/thanks", "Order #72")
```

### Two-Stage Payments

To create a two-stage payment, pass the `capture: false` option. This will authorize the amount on the user's card without charging it.

```elixir
# Step 1: Authorize the payment
{:ok, payment} = Yookassa.create_payment("500.00", "RUB", "https://example.com/hold", "Table reservation", capture: false)
payment_id = payment["id"]

# After the user pays, the status will be "waiting_for_capture".
# You can now either capture or cancel this payment.

# Step 2 (Option A): Capture the payment to charge the card
{:ok, captured_payment} = Yookassa.capture_payment(payment_id)

# Step 2 (Option B): Cancel the authorization
{:ok, canceled_payment} = Yookassa.cancel_payment(payment_id)
```

### Creating a Refund

You can only refund payments with a `succeeded` status.

```elixir
{:ok, refund} = Yookassa.create_refund("succeeded_payment_id", "50.00", "RUB")
```

### Getting Information

```elixir
# Get details about a specific payment
{:ok, payment_info} = Yookassa.get_payment_info("any_payment_id")

# Get details about a specific refund
{:ok, refund_info} = Yookassa.get_refund_info("any_refund_id")
```

## Handling Webhooks (Optional)

This library provides a `Yookassa.WebhookHandler` Plug to process incoming notifications. **This library does not start a web server for you.** You are responsible for integrating the handler into your own application.

### Example with Plug and Cowboy

1.  Add `:plug_cowboy` to your dependencies in `mix.exs`.
2.  Add the server to your supervision tree in `lib/my_app/application.ex`. You can choose any port.

    ```elixir
    def start(_type, _args) do
      children = [
        # ... your other application processes ...
        {Plug.Cowboy, scheme: :http, plug: Yookassa.WebhookHandler, options: [port: 8080]}
      ]
      Supervisor.start_link(children, opts)
    end
    ```
3.  Set your YooKassa Webhook URL to: `https://your-domain.com/webhook`

### Example with Phoenix Framework

1.  Add the route to your `lib/my_app_web/router.ex`. You can choose any path.

    ```elixir
    post "/yookassa_notifications", to: Yookassa.WebhookHandler
    ```
2.  Set your YooKassa Webhook URL to: `https://your-domain.com/yookassa_notifications`