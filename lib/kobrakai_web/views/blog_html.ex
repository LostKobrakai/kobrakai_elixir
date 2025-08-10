defmodule KobrakaiWeb.BlogHTML do
  use KobrakaiWeb, :html

  embed_templates "blog_html/*"

  def index(assigns) do
    ~H"""
    <div>
      <h2 class="uppercase mb-6">{@og.title}</h2>
      <div class="sm:columns-2 lg:columns-3">
        <ol class="-my-4">
          <KobrakaiWeb.PageHTML.list_item
            :for={{p, index} <- @posts |> Enum.reverse() |> Enum.with_index()}
            class="opacity-0 animate-in animation-fill-mode-forwards stagger"
            headline={p.title}
            date={p.date}
            tags={p.tags}
            url={~p"/kolumne/#{p.id}"}
            style={"--index: #{index}"}
          />
        </ol>
      </div>
    </div>
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
          {live_render(@conn, Module.concat([live]))}
        <% {:html, html} -> %>
          {Phoenix.HTML.raw(html)}
      <% end %>
    <% end %>
    """
  end
end
