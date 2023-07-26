defmodule KobrakaiWeb.ImagePlug do
  use Plug.Builder
  import Plug.Conn

  plug PlugCacheControl,
    directives: [
      :public,
      max_age: {1, :hour},
      stale_while_revalidate: {20, :minutes}
    ]

  plug :check_hmac
  plug :build_image

  def init(opts) do
    %{
      secret: Keyword.fetch!(opts, :secret),
      finch: Keyword.fetch!(opts, :finch)
    }
  end

  def call(conn, opts) do
    secret =
      case opts.secret do
        secret when is_binary(secret) -> secret
        secret when is_function(secret, 0) -> secret.()
      end

    conn
    |> assign(:secret, secret)
    |> assign(:finch, opts.finch)
    |> super([])
  end

  defp check_hmac(conn, _) do
    if ThumborPath.valid?(Path.join(conn.path_info), conn.assigns.secret) do
      conn
    else
      conn
      |> send_resp(:forbidden, "")
      |> halt()
    end
  end

  defp build_image(conn, _) do
    %ThumborPath{} = thumbor_path = conn.path_info |> Path.join() |> ThumborPath.parse()

    {:ok, response} =
      Finch.build(:get, thumbor_path.source)
      |> Finch.request(conn.assigns.finch)

    {:ok, image} = Image.from_binary(response.body)
    {width, height, _} = Image.shape(image)

    crop =
      if width <= height do
        case thumbor_path.vertical_align || :middle do
          :top -> :high
          :middle -> :center
          :bottom -> :low
        end
      else
        case thumbor_path.horizontal_align || :center do
          :left -> :high
          :center -> :center
          :right -> :low
        end
      end

    image =
      Enum.reduce(thumbor_path |> Map.from_struct(), image, fn
        {:size, {a, b}}, image ->
          Image.thumbnail!(
            image,
            size_and_dimensions_to_thumbnail({a, b}, {width, height}),
            crop: crop
          )

        _, image ->
          image
      end)

    conn = send_chunked(conn, 200)

    image
    |> Image.stream!(suffix: ".jpg", buffer_size: 5_242_880, progressive: true, quality: 100)
    |> Enum.reduce_while(conn, fn chunk, conn ->
      case chunk(conn, chunk) do
        {:ok, conn} -> {:cont, conn}
        {:error, :closed} -> {:halt, conn}
      end
    end)
  end

  defp size_and_dimensions_to_thumbnail({0, b}, {w, h}) do
    a = trunc(w / h * b)
    size_and_dimensions_to_thumbnail({a, b}, {w, h})
  end

  defp size_and_dimensions_to_thumbnail({a, 0}, {w, h}) do
    b = trunc(h / w * a)
    size_and_dimensions_to_thumbnail({a, b}, {w, h})
  end

  defp size_and_dimensions_to_thumbnail({a, b}, _), do: "#{a}x#{b}"
end
