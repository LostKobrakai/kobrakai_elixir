defmodule KobrakaiWeb.WebfingerController do
  use KobrakaiWeb, :controller

  @aliases ["acct:lostkobrakai@kobrakai.de", "acct:lostkobrakai@hachyderm.io"]

  plug ETag.Plug
  plug :resource_required

  def finger(conn, %{"resource" => resource}) do
    case resource do
      r when r in @aliases ->
        data = %{
          subject: "acct:lostkobrakai@kobrakai.de",
          aliases: [
            "acct:lostkobrakai@hachyderm.io",
            "https://hachyderm.io/@lostkobrakai",
            "https://hachyderm.io/users/lostkobrakai"
          ],
          links: [
            %{
              rel: "http://webfinger.net/rel/profile-page",
              type: "text/html",
              href: "https://hachyderm.io/@lostkobrakai"
            },
            %{
              rel: "self",
              type: "application/activity+json",
              href: "https://hachyderm.io/users/lostkobrakai"
            },
            %{
              rel: "self",
              href: "https://kobrakai.de"
            },
            %{
              rel: "http://ostatus.org/schema/1.0/subscribe",
              template: "https://hachyderm.io/authorize_interaction?uri={uri}"
            }
          ]
        }

        response = Phoenix.json_library().encode_to_iodata!(data)

        conn
        |> put_resp_content_type("application/jrd+json")
        |> send_resp(200, response)

      _ ->
        send_resp(conn, :not_found, "")
    end
  end

  defp resource_required(conn, _) do
    if conn.query_params["resource"] do
      conn
    else
      conn
      |> send_resp(:bad_request, "")
      |> halt()
    end
  end
end
