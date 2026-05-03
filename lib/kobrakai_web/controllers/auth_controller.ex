defmodule KobrakaiWeb.AuthController do
  use KobrakaiWeb, :controller
  require Logger
  alias KobrakaiWeb.Authentication.ClientStore
  alias Oidcc.Plug.AuthorizationCallback

  plug :store_return_to when action in [:initiate]

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

  defp store_return_to(conn, _opts) do
    return_to = conn.params["return_to"] || "/"
    put_session(conn, "return_to", return_to)
  end

  def initiate(conn, _params) do
    conn
  end

  def authenticate(%{private: %{AuthorizationCallback => result}} = conn, _params) do
    case result do
      {:ok, {_token, userinfo}} ->
        return_to = get_session(conn, "return_to") || "/"

        conn
        |> put_session("oidcc_claims", userinfo)
        |> delete_session("return_to")
        |> redirect(to: return_to)

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
