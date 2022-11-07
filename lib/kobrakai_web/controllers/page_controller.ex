defmodule KobrakaiWeb.PageController do
  use KobrakaiWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home,
      page_title: "Home",
      projects: Kobrakai.Portfolio.featured_projects(),
      posts: Kobrakai.Blog.all_posts(),
      images: [
        "1077/20150819-_ben0528",
        "1080/20150819-_ben0257-bearbeitet",
        "1081/ben7148-bearbeitet",
        "1044/ben7320-bearbeitet",
        "1018/20140404-_ben6885-bearbeitet",
        "1082/20130705-_ben0348-bearbeitet"
      ]
    )
  end
end
