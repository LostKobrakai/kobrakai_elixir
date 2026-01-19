defmodule KobrakaiWeb.PageController do
  use KobrakaiWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> merge_open_graph(title: "Home")
    |> render(:home,
      projects: Kobrakai.Portfolio.featured_projects(),
      posts: Kobrakai.Blog.all_posts(),
      images: Kobrakai.Photography.homepage(),
      videos: Kobrakai.Video.list_videos() |> Enum.reverse() |> Enum.take(4)
    )
  end
end
