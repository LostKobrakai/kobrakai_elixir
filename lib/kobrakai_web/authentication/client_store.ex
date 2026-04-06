defmodule KobrakaiWeb.Authentication.ClientStore do
  alias Phoenix.Controller
  alias Oidcc.ClientContext
  alias Oidcc.Plug.ClientStore

  @behaviour ClientStore

  @impl ClientStore
  def get_client_context(conn) do
    controller = Controller.controller_module(conn)
    opts = Application.fetch_env!(:kobrakai, controller)

    ClientContext.from_configuration_worker(
      Keyword.fetch!(opts, :provider),
      Keyword.fetch!(opts, :client_id),
      Keyword.fetch!(opts, :client_secret),
      Keyword.get(opts, :client_context_opts, %{})
    )
  end
end
