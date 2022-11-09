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

  def body(assigns) do
    stream = Stream.cycle([:html, :live])
    parts = :binary.split(assigns.content, ["<!-- [", "] -->"], [:global])
    assigns = assigns |> assign(:parts, Enum.zip([stream, parts]))

    ~H"""
    <%= for p <- @parts do %>
      <%= case p do %>
        <% {:live, live} -> %>
          <%= live_render(@conn, Module.concat([live])) %>
        <% {:html, html} -> %>
          <%= Phoenix.HTML.raw(html) %>
      <% end %>
    <% end %>
    """
  end
end
