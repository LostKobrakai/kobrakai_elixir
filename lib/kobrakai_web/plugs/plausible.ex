defmodule KobrakaiWeb.Plausible do
  def init(_), do: []

  def call(conn, _) do
    case conn.path_info do
      path when path in [["js", "script.js"], ["api", "events"]] ->
        conn
        |> Plug.run([
          {
            ReverseProxyPlug,
            upstream: "https://plausible.io",
            client: Kobrakai.ReverseProxyPlug.FinchClient,
            response_mode: :buffer
          }
        ])
        |> Plug.Conn.halt()

      _ ->
        conn
    end
  end
end
