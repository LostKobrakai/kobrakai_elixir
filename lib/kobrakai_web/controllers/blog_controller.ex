defmodule KobrakaiWeb.BlogController do
  use KobrakaiWeb, :controller
  alias Kobrakai.Blog

  plug :put_layout, html: {KobrakaiWeb.Layouts, :blog}

  def index(conn, _) do
    render(conn, :index, posts: Blog.all_posts())
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post_by_id!(id)
    render(conn, :show, post: post, page_title: post.title)
  end
end
