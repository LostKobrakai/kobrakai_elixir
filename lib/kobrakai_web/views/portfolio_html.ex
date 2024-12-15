defmodule KobrakaiWeb.PortfolioHTML do
  use KobrakaiWeb, :html
  alias Kobrakai.Portfolio

  embed_templates "portfolio_html/*"

  def index(assigns) do
    ~H"""
    <div>
      <h2 class="uppercase mb-6"><%= @og.title %></h2>
      <div class="sm:columns-2 lg:columns-3">
        <ol class="-my-4">
          <KobrakaiWeb.PageHTML.list_item
            :for={{p, index} <- @projects |> Enum.reverse() |> Enum.with_index()}
            class={"opacity-0 animate-in animation-fill-mode-forwards animation-delay-#{index * 55}"}
            headline={p.title}
            date={p.date}
            tags={p.tags}
            url={~p"/projekte/#{p.id}"}
          />
        </ol>
      </div>
    </div>
    """
  end

  attr :data, :map, required: true

  def primary(%{data: %{"type" => "image"}} = assigns) do
    # TODO: Responsive sizes
    ~H"""
    <picture class="block w-full">
      <source
        :for={ext <- Portfolio.file_types()}
        type={"image/#{ext}"}
        srcset={srcset(@data["source"], ext, Portfolio.primary_image_sizes())}
        sizes="100vw"
      />
      <img src={Portfolio.static_path(@data["source"], 1250, :jpeg)} alt={@data["alt"]} />
    </picture>
    """
  end

  def primary(%{data: %{"type" => "video"}} = assigns) do
    ~H"""
    <div class="w-full aspect-w-16 aspect-h-9 bg-[#ddd]">
      <iframe
        class="w-full h-full border-0 absolute inset-0"
        src={"https://iframe.mediadelivery.net/embed/73895/#{@data["bunny"]}?autoplay=false&preload=false"}
        loading="lazy"
        allowfullscreen="true"
      >
      </iframe>
    </div>
    """
  end

  def primary(%{data: %{"type" => "pdf"}} = assigns) do
    ~H"""
    <div class="w-full aspect-w-16 aspect-h-9 bg-[#ddd]">
      <object class="video-iframe" data={@data["file"] <> "#zoom=page-fit"} type="application/pdf">
        <p>
          <a download href={@data["file"]}>Herunterladen</a>
        </p>
      </object>
    </div>
    """
  end

  attr :data, :map, required: true

  def secondary(%{data: %{"type" => "image"}} = assigns) do
    # TODO: Responsive sizes
    ~H"""
    <picture class="block w-full">
      <source
        :for={ext <- Portfolio.file_types()}
        media="(min-width: 1024px)"
        type={"image/#{ext}"}
        srcset={srcset(@data["source"], ext, Portfolio.secondary_image_sizes())}
        sizes="50vw"
      />
      <source
        :for={ext <- Portfolio.file_types()}
        type={"image/#{ext}"}
        srcset={srcset(@data["source"], ext, Portfolio.secondary_image_sizes())}
        sizes="100vw"
      />
      <img src={Portfolio.static_path(@data["source"], 600, :jpeg)} alt={@data["alt"]} />
    </picture>
    """
  end

  def secondary(%{data: %{"type" => "pdf"}} = assigns) do
    ~H"""
    <div class="w-full aspect-w-16 aspect-h-9 bg-[#ddd]">
      <object class="video-iframe" data={@data["file"] <> "#zoom=page-fit"} type="application/pdf">
        <p>
          <a download href={@data["file"]}>Herunterladen</a>
        </p>
      </object>
    </div>
    """
  end

  defp srcset(source, ext, sizes) do
    Enum.map_join(sizes, ", ", fn size ->
      "#{Portfolio.static_path(source, size, ext)} #{size}w"
    end)
  end
end
