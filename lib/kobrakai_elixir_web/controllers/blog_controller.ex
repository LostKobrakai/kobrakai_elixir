defmodule KobrakaiElixirWeb.BlogController do
  use KobrakaiElixirWeb, :controller
  alias KobrakaiElixir.Blog

  def show(conn, %{"id" => id}) do
    post = Blog.get_post_by_id!(id)
    render(conn, :show, post: post, page_title: post.title)
  end
end
