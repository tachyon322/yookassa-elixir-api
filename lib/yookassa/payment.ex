defmodule Yookassa.Payment do
  @moduledoc """
  Represents a payment object from the YooKassa API.

  This struct encapsulates all the information about a payment, including its current status,
  amount, timestamps, and additional metadata. It provides a convenient way to work with
  payment data returned by the YooKassa API.

  ## Fields

    - `id`: Unique payment identifier (string)
    - `status`: Current payment status (e.g., "pending", "succeeded", "canceled")
    - `amount`: Payment amount with currency information (map with "value" and "currency" keys)
    - `paid`: Boolean indicating if the payment was successfully processed
    - `created_at`: ISO 8601 timestamp when the payment was created
    - `description`: Payment description provided during creation
    - `confirmation`: Confirmation details for redirect-based payments
    - `test`: Boolean indicating if this is a test payment
    - `refunded_amount`: Amount that has been refunded (if any)
    - `receipt_registration`: Receipt registration status
    - `metadata`: Additional custom metadata associated with the payment

  ## Usage

  Payment structs are typically created from API responses using the `from_map/1` function:

      payment = Yookassa.Payment.from_map(api_response_body)
  """

  @enforce_keys [:id, :status, :amount, :paid]
  defstruct [:id, :status, :amount, :paid, :created_at, :description, :confirmation, :test, :refunded_amount, :receipt_registration, :metadata]

  @doc """
  Creates a Payment struct from a map received from the YooKassa API.

  This function converts string keys from the API response to atom keys in the struct,
  handling only the known fields defined in the Payment struct. Unknown fields are
  converted to atoms but may not be accessible as struct fields.

  ## Parameters

    - `map`: A map with string keys as returned by the YooKassa API

  ## Returns

  A `Yookassa.Payment` struct with the converted data.

  ## Examples

      api_response = %{"id" => "123", "status" => "succeeded", ...}
      payment = Yookassa.Payment.from_map(api_response)
  """
  def from_map(%{} = map) do
    # Convert keys from strings to atoms if they match struct fields
    atomized_map = for {key, val} <- map, into: %{} do
      case key do
        "id" -> {:id, val}
        "status" -> {:status, val}
        "amount" -> {:amount, val}
        "paid" -> {:paid, val}
        "created_at" -> {:created_at, val}
        "description" -> {:description, val}
        "confirmation" -> {:confirmation, val}
        "test" -> {:test, val}
        "refunded_amount" -> {:refunded_amount, val}
        "receipt_registration" -> {:receipt_registration, val}
        "metadata" -> {:metadata, val}
        _ -> {String.to_atom(key), val}
      end
    end
    struct(__MODULE__, atomized_map)
  end
end
