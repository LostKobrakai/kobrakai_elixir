defmodule KobrakaiWeb.VideoController do
  use KobrakaiWeb, :controller

  def index(conn, _) do
    conn
    |> merge_open_graph(title: "Videos")
    |> render(:index, videos: Kobrakai.Video.list_videos())
  end

  def show(conn, %{"id" => id}) do
    video = Kobrakai.Video.get_video(id)

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
