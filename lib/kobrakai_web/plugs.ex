defmodule KobrakaiWeb.Plugs do
  import Plug.Conn
  import Phoenix.Controller

  def assign_current_path(conn, _) do
    assign(conn, :current_path, current_path(conn))
  end

  def assign_host(conn, _) do
    put_router_url(conn, conn.host)
  end
end
