defmodule Kobrakai.Video do
  use KobrakaiWeb, :verified_routes

  def list_videos do
    Kobrakai.Bold.list_videos!().body["data"]
    |> Enum.map(&Kobrakai.Bold.video_response_mapping/1)
    |> Enum.concat(external_videos())
    |> Enum.sort_by(& &1.date, Date)
  end

  def get_video(id) do
    Kobrakai.Bold.get_video!(id).body["data"]
    |> Kobrakai.Bold.video_response_mapping()
  end

  def external_videos() do
    [
      %{
        url: "https://www.youtube.com/watch?v=YJp6r6IXP6U",
        id: "elixir-conf-eu-2023",
        title: "Wired up! - Using ecto without schemas*",
        date: ~D[2023-04-23],
        tags: ["video"],
        thumbnail: url(~p"/images/elixir-conf-eu-2023.jpg")
      },
      %{
        url: "https://video.goatmire.com/v/wp5qe",
        id: "goatmire-elixir-2025",
        title: "State – and where to find it",
        date: ~D[2025-09-12],
        tags: ["video"],
        thumbnail:
          "https://uploads.eu1.boldvideo.io/uploads/bt_goatmire/thumbnails/d1595abb-747e-45d9-8b6d-171565e43aa0.jpg"
      }
    ]
  end
end
