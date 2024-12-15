defmodule KobrakaiWeb.VideoController do
  use KobrakaiWeb, :controller

  def index(conn, _) do
    videos =
      Kobrakai.Bold.list_videos!().body["data"]
      |> Enum.sort_by(& &1["published_at"])
      |> Enum.map(&Kobrakai.Bold.video_response_mapping/1)

    conn
    |> merge_open_graph(title: "Videos")
    |> render(:index, videos: videos)
  end

  def show(conn, %{"id" => id}) do
    video =
      Kobrakai.Bold.get_video!(id).body["data"]
      |> Kobrakai.Bold.video_response_mapping()

    conn
    |> merge_open_graph(
      title: video.title,
      description: video.description,
      type: "video.episode",
      image: video.thumbnail,
      video: video.src,
      video_duration: video.duration
    )
    |> render(:show, video: video)
  end
end
