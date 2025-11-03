defmodule Yookassa.Refund do
  @moduledoc """
  Represents a refund object from the YooKassa API.

  This struct contains information about a refund transaction, including its status,
  amount, associated payment ID, and timestamps. It provides a structured way to
  handle refund data returned by the YooKassa API.

  ## Fields

    - `id`: Unique refund identifier (string)
    - `status`: Current refund status (e.g., "pending", "succeeded", "canceled")
    - `amount`: Refund amount with currency information (map with "value" and "currency" keys)
    - `payment_id`: ID of the payment this refund is associated with
    - `created_at`: ISO 8601 timestamp when the refund was created
    - `cancellation_details`: Details about why the refund was canceled (if applicable)
    - `refund_authorization_details`: Authorization details for the refund

  ## Usage

  Refund structs are typically created from API responses using the `from_map/1` function:

      refund = Yookassa.Refund.from_map(api_response_body)
  """

  @enforce_keys [:id, :status, :amount, :payment_id, :created_at]
  defstruct [:id, :status, :amount, :payment_id, :created_at, :cancellation_details, :refund_authorization_details]

  @doc """
  Creates a Refund struct from a map received from the YooKassa API.

  This function converts string keys from the API response to atom keys in the struct,
  handling only the known fields defined in the Refund struct. Unknown fields are
  converted to atoms but may not be accessible as struct fields.

  ## Parameters

    - `map`: A map with string keys as returned by the YooKassa API

  ## Returns

  A `Yookassa.Refund` struct with the converted data.

  ## Examples

      api_response = %{"id" => "456", "status" => "succeeded", ...}
      refund = Yookassa.Refund.from_map(api_response)
  """
  def from_map(%{} = map) do
    # Convert keys from strings to atoms if they match struct fields
    atomized_map = for {key, val} <- map, into: %{} do
      case key do
        "id" -> {:id, val}
        "status" -> {:status, val}
        "amount" -> {:amount, val}
        "payment_id" -> {:payment_id, val}
        "created_at" -> {:created_at, val}
        "cancellation_details" -> {:cancellation_details, val}
        "refund_authorization_details" -> {:refund_authorization_details, val}
        _ -> {String.to_atom(key), val}
      end
    end
    struct(__MODULE__, atomized_map)
  end
end
