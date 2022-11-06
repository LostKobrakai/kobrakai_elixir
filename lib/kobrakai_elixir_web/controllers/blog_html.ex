defmodule KobrakaiElixirWeb.BlogHTML do
  use KobrakaiElixirWeb, :html

  def show(assigns) do
    ~H"""
    <%= Phoenix.HTML.raw(@post.body) %>
    """
  end
end
