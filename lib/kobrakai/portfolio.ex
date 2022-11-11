defmodule Kobrakai.Portfolio do
  use NimblePublisher,
    build: Kobrakai.Portfolio.Project,
    parser: Kobrakai.Portfolio.Project,
    from: "static/projects/**/*.md",
    as: :projects,
    highlighters: [:makeup_html, :makeup_elixir, :makeup_erlang, :kobrakai]

  alias Kobrakai.Blog.NotFoundError

  @show_drafts Application.compile_env!(:kobrakai, [__MODULE__, :show_drafts])

  # The @projects variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all projects by descending date.
  @projects @projects
            |> Enum.sort_by(fn project -> project.date end, Date)
            |> Enum.filter(fn project -> !project.draft || @show_drafts end)

  # And finally export them
  def all_projects, do: @projects
  def featured_projects, do: Enum.filter(all_projects(), fn p -> "featured" in p.tags end)

  def get_project_by_id!(id) do
    Enum.find(all_projects(), &(&1.id == id)) ||
      raise NotFoundError, "project with id=#{id} not found"
  end

  def primary_image_sizes, do: [600, 1250, 2500]
  def secondary_image_sizes, do: [600, 1250]
  def file_types, do: [:jpeg]

  def static_path(path, size, ext) do
    path
    |> Path.split()
    |> List.update_at(-1, fn filename ->
      base = Path.basename(filename, Path.extname(filename))
      "#{base}@#{size}.#{ext}"
    end)
    |> Path.join()
  end
end
