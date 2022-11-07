defmodule KobrakaiWeb.PortfolioHTML do
  use KobrakaiWeb, :html

  embed_templates "portfolio_html/*"

  def index(assigns) do
    ~H"""
    <ol>
      <li :for={project <- @projects}>
        <.link class="text-blue-600" navigate={~p"/projekte/#{project.id}"}>
          <%= project.title %>
        </.link>
      </li>
    </ol>
    """
  end

  attr :data, :map, required: true

  def primary(%{data: %{"type" => "image"}} = assigns) do
    # TODO: Responsive sizes
    ~H"""
    <picture class="block w-full">
      <img src={@data["source"]} alt={@data["alt"]} />
    </picture>
    """
  end

  def primary(%{data: %{"type" => "video"}} = assigns) do
    ~H"""
    <div class="video-container">
      <iframe
        allowfullscreen
        class="video-iframe"
        frameborder="0"
        height="1080"
        mozallowfullscreen
        src="//player.vimeo.com/video/{{ primary.vimeo }}?title=0&amp;byline=0&amp;portrait=0&amp;color=ffffff"
        webkitallowfullscreen
        width="1920"
      >
      </iframe>
    </div>
    """
  end

  def primary(%{data: %{"type" => "pdf"}} = assigns) do
    ~H"""
    <div class="video-container">
      <iframe
        allowfullscreen
        class="video-iframe"
        frameborder="0"
        height="1080"
        mozallowfullscreen
        src="/assets/pdf/web/viewer.html?file=../../{{ primary.file }}#zoom=page-fit"
        webkitallowfullscreen
        width="1920"
      >
      </iframe>
    </div>
    """
  end

  attr :data, :map, required: true

  def secondary(%{data: %{"type" => "image"}} = assigns) do
    # TODO: Responsive sizes
    ~H"""
    <picture class="block w-full">
      <img src={@data["source"]} alt={@data["alt"]} />
    </picture>
    """
  end

  def secondary(%{data: %{"type" => "pdf"}} = assigns) do
    ~H"""
    <div class="video-container">
      <object class="video-iframe" data="/assets/{{ item.file }}#zoom=page-fit" type="application/pdf">
        <p>
          <a download href="/assets/{{ item.file }}">Herunterladen</a>
        </p>
      </object>
    </div>
    """
  end
end
