defmodule KobrakaiWeb.CustomController do
  use KobrakaiWeb, :controller

  def photography(conn, _) do
    photos = Kobrakai.Photography.all_images()
    render(conn, :photography, page_title: "Fotografie", photos: photos)
  end

  def cv(conn, _) do
    render(conn, :cv,
      page_title: "Werdegang",
      elixir_forum_stats: Kobrakai.CV.elixir_forum_stats()
    )
  end

  def contact(conn, _) do
    render(conn, :contact, page_title: "Kontakt")
  end

  def legal(conn, _) do
    render(conn, :legal, page_title: "Impressum")
  end
end
