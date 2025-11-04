# Yookassa

An Elixir client for the YooKassa API v3. This library provides a simple and convenient way to integrate YooKassa payment processing into your Elixir applications, supporting payments, refunds, and webhook notifications.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `yookassa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:yookassa, "~> 0.1.2"}
  ]
end
```

## Configuration

Add the following to your `config/config.exs`:

```elixir
config :yookassa,
  api_url: "https://api.yookassa.ru/v3",
  shop_id: "your_shop_id",
  secret_key: "your_secret_key",
```

## Usage

### Creating a Payment

```elixir
{:ok, payment} = Yookassa.create_payment("100.00", "RUB", "https://example.com/return", "Order #123")
```

### Capturing a Payment (for two-stage payments)

```elixir
{:ok, captured} = Yookassa.capture_payment("payment_id")
```

### Canceling a Payment

```elixir
{:ok, canceled} = Yookassa.cancel_payment("payment_id")
```

### Creating a Refund

```elixir
{:ok, refund} = Yookassa.create_refund("payment_id", "50.00", "RUB")
```

### Retrieving Payment Information

```elixir
{:ok, payment_info} = Yookassa.get_payment_info("payment_id")
```

### Retrieving Refund Information

```elixir
{:ok, refund_info} = Yookassa.get_refund_info("refund_id")
```

## Webhook Handling

The library includes a built-in webhook handler that listens for YooKassa notifications on `/webhook`. It supports the following events:

- `payment.succeeded`: Payment completed successfully
- `payment.canceled`: Payment was canceled
- `payment.waiting_for_capture`: Payment is waiting for capture (two-stage payments)
- `payment.pending`: Payment is pending processing
- `refund.succeeded`: Refund completed successfully
- `refund.canceled`: Refund was canceled

The webhook server runs on port 4545 by default (configurable via `:webhook_port` in config) and logs events to the console. In production, replace the logging with your business logic.

## API Reference

### Payment Functions

- [`create_payment/5`](lib/yookassa.ex:52:52): Creates a new payment with specified parameters.
- [`capture_payment/2`](lib/yookassa.ex:106:106): Confirms capture of an authorized payment.
- [`cancel_payment/1`](lib/yookassa.ex:131:131): Cancels a payment waiting for capture.
- [`get_payment_info/1`](lib/yookassa.ex:149:149): Retrieves information about a specific payment.

### Refund Functions

- [`create_refund/3`](lib/yookassa.ex:177:177): Creates a refund for a payment.
- [`get_refund_info/1`](lib/yookassa.ex:202:202): Retrieves information about a specific refund.

## Error Handling

All functions return `{:ok, result}` on success or `{:error, details}` on failure. Error details include HTTP status codes and messages from the YooKassa API.
