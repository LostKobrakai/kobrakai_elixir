defmodule KobrakaiWeb.BlogController do
  use KobrakaiWeb, :controller
  alias Kobrakai.Blog

  def index(conn, _) do
    render(conn, :index, posts: Blog.all_posts(), page_title: "Kolumne")
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post_by_id!(id)

    render(conn, :show,
      post: post,
      page_title: post.title,
      og_type: "article",
      excerpt: post.excerpt
    )
  end
end
