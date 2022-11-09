defmodule KobrakaiWeb.BlogHTML do
  use KobrakaiWeb, :html

  embed_templates "blog_html/*"

  def index(assigns) do
    ~H"""
    <ol>
      <li :for={post <- @posts}>
        <.link class="text-blue-600" navigate={~p"/kolumne/#{post.id}"}><%= post.title %></.link>
      </li>
    </ol>
    """
  end
end
