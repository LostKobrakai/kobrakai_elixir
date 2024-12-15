defmodule KobrakaiWeb.OpenGraph do
  use KobrakaiWeb, :html
  defstruct [:title, :type, :description, :image, :video, :video_duration, :canonical]

  attr :og, __MODULE__, required: true

  def render(%{og: %__MODULE__{} = og} = assigns) do
    meta =
      [
        if(og.title, do: %{name: "og:title", content: og.title}),
        if(og.type, do: %{name: "og:type", content: og.type}),
        if(og.description, do: %{name: "description", content: og.description}),
        if(og.description, do: %{name: "og:description", content: og.description}),
        if(og.canonical, do: %{name: "og:url", content: og.canonical}),
        if(og.image, do: %{name: "og:image", content: og.image}),
        if(og.video, do: %{name: "og:video", content: og.video}),
        if(og.video_duration, do: %{name: "og:video:duration", content: og.video_duration}),
        if(og.canonical, do: %{name: "og:url", content: og.canonical})
      ]
      |> Enum.filter(& &1)

    link =
      [
        if(og.canonical, do: %{rel: "canonical", href: og.canonical})
      ]
      |> Enum.filter(& &1)

    assigns = assign(assigns, meta: meta, link: link)

    ~H"""
    <meta :for={meta_item <- @meta} {meta_item} />
    <link :for={link_item <- @link} {link_item} />
    """
  end

  def merge_open_graph(conn, values) do
    base = conn.assigns[:og] || %__MODULE__{}
    next = struct!(base, values)
    Plug.Conn.assign(conn, :og, next)
  end
end
