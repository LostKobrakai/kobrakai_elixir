defmodule KobrakaiWeb.CustomController do
  use KobrakaiWeb, :controller

  def photography(conn, _) do
    photos = Kobrakai.Photography.all_images()

    conn
    |> merge_open_graph(title: "Fotografie")
    |> render(:photography, photos: photos)
  end

  def cv(conn, _) do
    conn
    |> merge_open_graph(title: "Werdegang")
    |> render(:cv, elixir_forum_stats: Kobrakai.CV.elixir_forum_stats())
  end

  def contact(conn, _) do
    conn
    |> merge_open_graph(title: "Kontakt")
    |> render(:contact)
  end

  def legal(conn, _) do
    conn
    |> merge_open_graph(title: "Impressum")
    |> render(:legal)
  end
end
