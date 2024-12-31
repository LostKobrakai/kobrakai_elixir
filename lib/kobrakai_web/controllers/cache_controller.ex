defmodule KobrakaiWeb.CacheController do
  use KobrakaiWeb, :controller

  def show(conn, _) do
    json(conn, %{
      static: [
        ~p"/assets/video.js",
        ~p"/assets/app.css",
        ~p"/assets/app.js",
        ~p"/images/signee.png",
        ~p"/images/pfeil.png",
        ~p"/images/avatar.jpg",
        ~p"/font/noway-regular-webfont.woff",
        ~p"/font/noway-regular-webfont.woff2",
        ~p"/font/Virgil.woff2"
      ]
    })
  end
end
