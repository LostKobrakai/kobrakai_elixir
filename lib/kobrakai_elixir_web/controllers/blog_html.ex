defmodule KobrakaiWeb.BlogHTML do
  use KobrakaiWeb, :html

  def show(assigns) do
    ~H"""
    <%= Phoenix.HTML.raw(@post.body) %>
    """
  end
end
