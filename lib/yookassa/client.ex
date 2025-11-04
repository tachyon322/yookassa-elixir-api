# lib/yookassa/client.ex
defmodule Yookassa.Client do
  @moduledoc """
  Low-level HTTP client for interacting with the YooKassa API.
  """

  @doc """
  Sends a POST request to the YooKassa API.
  """
  def post(path, body) do
    # Now we create the request right here, reading the config at runtime
    req = base_req()

    Req.post(req,
      url: path,
      json: body,
      headers: idempotence_header()
    )
  end

  @doc """
  Sends a GET request to the YooKassa API.
  """
  def get(path) do
    req = base_req()
    Req.get(req, url: path)
  end

  # --- NEW PRIVATE FUNCTIONS ---

  # This function will create the base request every time it's needed
  defp base_req do
    # We use Application.get_env/2, which works at runtime
    api_url = Application.get_env(:yookassa, :api_url)
    shop_id = Application.get_env(:yookassa, :shop_id)
    secret_key = Application.get_env(:yookassa, :secret_key)

    # Check that the user has configured the config
    unless shop_id && secret_key do
      raise "Yookassa configuration is missing. Please check your config.exs file for :shop_id and :secret_key"
    end

    Req.new(
      base_url: api_url,
      auth: {:basic, "#{shop_id}:#{secret_key}"}
    )
  end

  defp idempotence_header do
    %{"Idempotence-Key" => UUID.uuid4()}
  end
end
