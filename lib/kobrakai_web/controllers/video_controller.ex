defmodule KobrakaiWeb.VideoController do
  use KobrakaiWeb, :controller

  def index(conn, _) do
    videos =
      for video <- Kobrakai.Bold.list_videos!().body["data"] do
        Kobrakai.Bold.video_response_mapping(video)
      end

    render(conn, :index, videos: videos, page_title: "Videos")
  end

  def show(conn, %{"id" => id}) do
    video =
      Kobrakai.Bold.get_video!(id).body["data"]
      |> Kobrakai.Bold.video_response_mapping()

    render(conn, :show, video: video)
  end
end
