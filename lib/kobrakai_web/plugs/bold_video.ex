defmodule KobrakaiWeb.BoldVideo do
  def init(_), do: []

  def call(conn, _) do
    case conn.path_info do
      ["api", "bold" | rest] ->
        conn
        |> Plug.Conn.put_req_header("authorization", Kobrakai.Bold.api_key())
        |> Plug.forward(
          rest,
          ReverseProxyPlug,
          ReverseProxyPlug.init(
            upstream: "https://app.boldvideo.io/",
            response_mode: :buffer
          )
        )
        |> Plug.Conn.halt()

      _ ->
        conn
    end
  end
end
