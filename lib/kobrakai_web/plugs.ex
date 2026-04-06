defmodule KobrakaiWeb.Plugs do
  use KobrakaiWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller

  def assign_current_path(conn, _) do
    assign(conn, :current_path, current_path(conn))
  end

  def set_robots(conn, value) when value in [:all, :noindex, :nofollow, :none] do
    assign(conn, :robots, value)
  end

  def put_hostname(conn, _) do
    Phoenix.Controller.put_router_url(conn, conn.host)
  end

  def current_user(conn, _) do
    data = get_session(conn, "oidcc_claims")
    assign(conn, :current_user, data)
  end

  def ensure_authenticated(conn, _) do
    if conn.assigns.current_user do
      conn
    else
      redirect(conn, to: ~p"/auth/initiate?state=#{current_path(conn)}")
    end
  end
end
