defmodule Yookassa.Application do
  @moduledoc """
  Application module for the Yookassa Elixir library.

  This module is responsible for starting the application and its supervision tree.
  It sets up the web server using Plug.Cowboy to handle webhook notifications from YooKassa.

  ## Configuration

  The application starts a Cowboy web server on port 4000 by default, which listens for
  webhook notifications at the `/webhook` endpoint. Make sure to configure your ngrok
  or reverse proxy to forward requests to this port.

  ## Usage

  This module is automatically started when the application boots. No manual intervention
  is required unless you need to customize the port or add additional children to the
  supervision tree.
  """

  use Application

  @doc """
  Starts the Yookassa application.

  This function is called when the application starts. It sets up the supervision tree
  with the webhook handler server.

  ## Parameters

    - `_type`: The type of application start (ignored)
    - `_args`: Application arguments (ignored)

  ## Returns

  Returns `{:ok, pid}` where `pid` is the supervisor process, or `{:error, reason}` if
  the application fails to start.
  """
  @impl true
  def start(_type, _args) do
    children = [
      # Add this line to start the web server
      # It will listen on port 4000 and forward all requests to our WebhookHandler
      {Plug.Cowboy, scheme: :http, plug: Yookassa.WebhookHandler, options: [port: 4000]}
    ]

    # Important! The port (here 4000) must match the one
    # you specified when starting ngrok (`ngrok http 4000`)

    opts = [strategy: :one_for_one, name: Yookassa.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
