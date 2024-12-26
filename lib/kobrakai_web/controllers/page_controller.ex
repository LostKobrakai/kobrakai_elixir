defmodule KobrakaiWeb.PageController do
  use KobrakaiWeb, :controller

  def home(conn, _params) do
    videos =
      Kobrakai.Bold.list_videos!().body["data"]
      |> Enum.sort_by(& &1["published_at"])
      |> Enum.take(4)
      |> Enum.map(&Kobrakai.Bold.video_response_mapping/1)
      |> Stream.concat(Stream.repeatedly(fn -> nil end))
      |> Enum.take(4)

    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> merge_open_graph(title: "Home")
    |> render(:home,
      projects: Kobrakai.Portfolio.featured_projects(),
      posts: Kobrakai.Blog.all_posts(),
      images: Kobrakai.Photography.homepage(),
      videos: videos
    )
  end
end
