defmodule Kobrakai.Portfolio do
  use NimblePublisher,
    build: Kobrakai.Portfolio.Project,
    parser: Kobrakai.Portfolio.Project,
    from: "static/projects/**/*.md",
    as: :projects,
    highlighters: [:makeup_elixir, :makeup_erlang]

  alias Kobrakai.Blog.NotFoundError

  @show_drafts Application.compile_env!(:kobrakai, [__MODULE__, :show_drafts])

  # The @projects variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all projects by descending date.
  @projects @projects
            |> Enum.sort_by(fn project -> project.date end, Date)
            |> Enum.filter(fn project -> !project.draft || @show_drafts end)

  # And finally export them
  def all_projects, do: @projects
  def featured_projects, do: Enum.filter(all_projects, fn p -> "featured" in p.tags end)

  def get_post_by_id!(id) do
    Enum.find(all_projects(), &(&1.id == id)) ||
      raise NotFoundError, "post with id=#{id} not found"
  end
end
