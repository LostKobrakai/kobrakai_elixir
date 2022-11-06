defmodule KobrakaiElixir.Blog do
  use NimblePublisher,
    build: KobrakaiElixir.Blog.Post,
    parser: KobrakaiElixir.Blog.Post,
    from: "posts/**/*.md",
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  alias KobrakaiElixir.Blog.NotFoundError

  # The @posts variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by descending date.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # And finally export them
  def all_posts, do: @posts

  def get_post_by_id!(id) do
    Enum.find(all_posts(), &(&1.id == id)) ||
      raise NotFoundError, "post with id=#{id} not found"
  end
end
