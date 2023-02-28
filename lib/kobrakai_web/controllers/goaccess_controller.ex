defmodule KobrakaiWeb.GoaccessController do
  alias Swoosh.Application
  use KobrakaiWeb, :controller

  def show(conn, _) do
    path = Application.app_dir(:kobrakai, "priv/report.html")

    # TODO complete
    if System.find_executable("goaccess") do
      {_, ""} =
        System.cmd("goaccess", ["--agent-list", "--config-file", "~/etc/goaccess.conf", ""])
    end

    command =
      "goaccess --agent-list --config-file ~/etc/goaccess.conf --log-file <(cat ~/logs/webserver/access_log*) --output report.html"
  end
end
