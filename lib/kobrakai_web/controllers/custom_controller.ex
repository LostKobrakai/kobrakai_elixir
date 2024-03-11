defmodule KobrakaiWeb.CustomController do
  use KobrakaiWeb, :controller

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
