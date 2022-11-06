defmodule KobrakaiWeb.PageController do
  use KobrakaiWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, page_title: "Home", posts: Kobrakai.Blog.all_posts())
  end
end
