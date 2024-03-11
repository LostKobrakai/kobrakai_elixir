defmodule Kobrakai.CV do
  @default %{
    num_posts: 5321,
    num_likes: 8821,
    num_solutions: 583
  }

  def elixir_forum_stats do
    :persistent_term.get({__MODULE__, :elixir_forum_stats}, @default)
  end

  def refresh_elixir_forum_stats do
    request = Finch.build(:get, "https://elixirforum.com/u/lostkobrakai/summary.json")

    with {:ok, %{status: 200, body: json}} <- Finch.request(request, Kobrakai.Finch),
         {:ok, data} <- Jason.decode(json),
         changeset = elixir_forum_stats_changeset(Map.get(data, "user_summary", %{})),
         {:ok, validated} <- Ecto.Changeset.apply_action(changeset, :validate) do
      data = %{
        num_posts: validated.post_count,
        num_likes: validated.likes_received,
        num_solutions: validated.solved_count
      }

      :persistent_term.put({__MODULE__, :elixir_forum_stats}, data)
    else
      _ -> :ok
    end
  end

  defp elixir_forum_stats_changeset(params) do
    {%{likes_received: nil, post_count: nil, solved_count: nil},
     %{likes_received: :integer, post_count: :integer, solved_count: :integer}}
    |> Ecto.Changeset.cast(params, [:likes_received, :post_count, :solved_count])
    |> Ecto.Changeset.validate_required([:likes_received, :post_count, :solved_count])
    |> Ecto.Changeset.validate_number(:likes_received, greater_than: 0)
    |> Ecto.Changeset.validate_number(:post_count, greater_than: 0)
    |> Ecto.Changeset.validate_number(:solved_count, greater_than: 0)
  end
end
