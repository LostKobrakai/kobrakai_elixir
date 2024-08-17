defmodule KobrakaiWeb.WebsocketUpgrade do
  @moduledoc """
  Plug to upgrade request to websocket connection and starting `WebSock` handler.
  """
  @behaviour Plug

  @impl Plug
  def init(handler), do: handler

  @impl Plug
  def call(%Plug.Conn{} = conn, handler) do
    conn
    |> Phoenix.Socket.Transport.check_origin(__MODULE__, KobrakaiWeb.Endpoint, [])
    |> case do
      %{halted: true} = conn ->
        conn

      conn ->
        conn
        |> WebSockAdapter.upgrade(handler, %{path_params: conn.path_params}, [])
        |> Plug.Conn.halt()
    end
  end
end
