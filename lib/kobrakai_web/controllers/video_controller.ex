defmodule KobrakaiWeb.VideoController do
  use KobrakaiWeb, :controller

  def index(conn, _) do
    videos =
      Kobrakai.Bold.list_videos!().body["data"]
      |> Enum.sort_by(& &1["published_at"])
      |> Enum.map(&Kobrakai.Bold.video_response_mapping/1)

    render(conn, :index, videos: videos, page_title: "Videos")
  end

  def show(conn, %{"id" => id}) do
    video =
      Kobrakai.Bold.get_video!(id).body["data"]
      |> Kobrakai.Bold.video_response_mapping()

    render(conn, :show, video: video, page_title: video.title)
  end
end
