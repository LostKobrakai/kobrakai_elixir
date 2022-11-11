defmodule Mix.Tasks.Images.Compile do
  @moduledoc "Compile all images of projects"
  @shortdoc "Compiles images"
  alias Kobrakai.Portfolio

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    primary =
      for p <- Portfolio.all_projects(),
          p.primary["type"] == "image",
          do: p.primary["source"]

    create_thumbnails(primary, Portfolio.primary_image_sizes())

    secondary =
      for p <- Portfolio.all_projects(),
          i <- p.secondary,
          i["type"] == "image",
          do: i["source"]

    create_thumbnails(secondary, Portfolio.secondary_image_sizes())
  end

  defp create_thumbnails(paths, sizes) do
    for path <- paths,
        source = Path.join("static", path),
        size <- sizes do
      dirname = "priv/static" |> Path.join(path) |> Path.dirname()

      File.mkdir_p!(dirname)
      {:ok, thumb} = Image.thumbnail(source, size)

      for ext <- Portfolio.file_types() do
        target = Portfolio.static_path(path, size, ext)
        Mix.shell().info("* Compiling #{path} => #{target}")
        {:ok, _} = Image.write(thumb, Path.join("priv/static", target), quality: 95)
      end
    end
  end
end
