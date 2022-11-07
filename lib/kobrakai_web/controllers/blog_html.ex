defmodule KobrakaiWeb.BlogHTML do
  use KobrakaiWeb, :html

  def index(assigns) do
    ~H"""
    <ol>
      <li :for={post <- @posts}>
        <.link class="text-blue-600" navigate={~p"/kolumne/#{post.id}"}><%= post.title %></.link>
      </li>
    </ol>
    """
  end

  def show(assigns) do
    ~H"""
    <%= Phoenix.HTML.raw(@post.body) %>
    """
  end
end
