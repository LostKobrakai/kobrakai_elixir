defmodule Kobrakai.Blog do
  use NimblePublisher,
    build: Kobrakai.Blog.Post,
    parser: Kobrakai.Blog.Post,
    from: "static/posts/**/*.md",
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  alias Kobrakai.Blog.NotFoundError

  @show_drafts Application.compile_env!(:kobrakai, [__MODULE__, :show_drafts])

  # The @posts variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by descending date.
  @posts @posts
         |> Enum.sort_by(fn post -> post.date end, Date)
         |> Enum.filter(fn post -> !post.draft || @show_drafts end)

  # And finally export them
  def all_posts, do: @posts

  def get_post_by_id!(id) do
    Enum.find(all_posts(), &(&1.id == id)) ||
      raise NotFoundError, "post with id=#{id} not found"
  end
end
