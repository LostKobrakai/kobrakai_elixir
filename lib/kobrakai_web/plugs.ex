defmodule KobrakaiWeb.Plugs do
  import Plug.Conn
  import Phoenix.Controller

  def assign_current_path(conn, _) do
    assign(conn, :current_path, current_path(conn))
  end

  def set_robots(conn, value) when value in [:all, :noindex, :nofollow, :none] do
    assign(conn, :robots, value)
  end
end
