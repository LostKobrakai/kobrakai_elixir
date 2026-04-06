defmodule KobrakaiWeb.AuthController do
  use KobrakaiWeb, :controller
  require Logger
  alias KobrakaiWeb.Authentication.ClientStore
  alias Oidcc.Plug.AuthorizationCallback

  plug Oidcc.Plug.Authorize,
       [
         client_store: ClientStore,
         redirect_uri: &__MODULE__.callback_uri/0,
         scopes: ["openid", "profile", "email"]
       ]
       when action in [:initiate]

  plug AuthorizationCallback,
       [client_store: ClientStore, redirect_uri: &__MODULE__.callback_uri/0]
       when action in [:authenticate]

  def initiate(conn, _params) do
    conn
  end

  def authenticate(%{private: %{AuthorizationCallback => result}} = conn, params) do
    case result do
      {:ok, {_token, userinfo}} ->
        conn
        |> put_session("oidcc_claims", userinfo)
        |> redirect(to: Map.get(params, "state", "/"))

      {:error, reason} ->
        Logger.debug("Auth failed with: #{inspect(reason)}")

        conn
        |> put_view(KobrakaiWeb.ErrorHTML)
        |> put_status(400)
        |> render(:"400")
    end
  end

  def deauthenticate(conn, params) do
    conn
    |> configure_session(renew: true)
    |> delete_session("oidcc_claims")
    |> redirect(to: Map.get(params, "state", "/"))
  end

  @doc false
  if redirect_host = Application.compile_env(:kobrakai, [__MODULE__, :redirect_host]) do
    @uri URI.new!(redirect_host)

    def callback_uri do
      url(@uri, ~p"/auth/authenticate")
    end
  else
    def callback_uri do
      url(~p"/auth/authenticate")
    end
  end
end
