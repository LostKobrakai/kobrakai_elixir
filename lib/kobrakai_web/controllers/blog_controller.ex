defmodule KobrakaiWeb.BlogController do
  use KobrakaiWeb, :controller
  alias Kobrakai.Blog

  def index(conn, _) do
    conn
    |> merge_open_graph(title: "Kolumne")
    |> render(:index, posts: Blog.all_posts())
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post_by_id!(id)

    conn
    |> merge_open_graph(
      title: post.title,
      description: post.excerpt,
      type: "article"
    )
    |> render(:show, post: post)
  end
end
