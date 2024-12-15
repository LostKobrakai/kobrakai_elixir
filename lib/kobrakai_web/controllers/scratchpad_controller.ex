defmodule KobrakaiWeb.ScratchpadController do
  use KobrakaiWeb, :controller

  @pads [
          %{
            id: "checkboxes",
            name: "Checkboxes",
            date: ~D[2022-12-26]
          }
        ]
        |> Enum.sort_by(& &1.date, Date)

  def index(conn, _) do
    conn
    |> merge_open_graph(title: "Scratchpad")
    |> render(:index, pads: @pads)
  end
end
