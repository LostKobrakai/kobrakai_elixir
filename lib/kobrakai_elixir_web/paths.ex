defmodule KobrakaiWeb.Paths do
  def init(_), do: []

  def call(conn, _) do
    Plug.Conn.assign(conn, :current_path, Phoenix.Controller.current_path(conn))
  end
end
