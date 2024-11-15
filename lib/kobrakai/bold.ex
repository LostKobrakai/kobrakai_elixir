defmodule Kobrakai.Bold do
  defmodule NotFoundError do
    defexception [:message]
  end

  defp req_options do
    config = Application.fetch_env!(:kobrakai, __MODULE__)

    Keyword.get_lazy(config, :req_options, fn ->
      [auth: Keyword.fetch!(config, :api_key)]
    end)
  end

  def new(options \\ []) do
    Req.new(base_url: "https://app.boldvideo.io/api/")
    |> Req.Request.append_request_steps(
      post: fn req ->
        with %{method: :get, body: <<_::binary>>} <- req do
          %{req | method: :post}
        end
      end
    )
    |> Req.Request.append_response_steps(
      http_errors: fn
        {req, %{status: 404}} ->
          {req, NotFoundError.exception("Failed to find resource at: #{req.url}")}

        {req, resp} ->
          {req, resp}
      end
    )
    |> Req.merge(req_options())
    |> Req.merge(options)
  end

  def list_videos!(options \\ []) do
    Keyword.merge(options, url: "videos/all")
    |> new()
    |> Req.request!()
  end

  def get_video!(id, options \\ []) do
    Keyword.merge(options, url: "videos/#{id}")
    |> new()
    |> Req.request!()
  end

  def video_response_mapping(video) do
    %{
      id: video["id"],
      title: video["title"],
      date:
        video["published_at"]
        |> NaiveDateTime.from_iso8601!()
        |> NaiveDateTime.to_date(),
      tags: ["video"],
      src: video["stream_url"],
      playback_id: video["playback_id"],
      chapters: video["chapters_url"],
      subtitles: [
        %{
          label: video["subtitles"]["label"],
          language: video["subtitles"]["language"],
          url: video["subtitles"]["url"]
        }
      ],
      duration: video["duration"],
      thumbnail: video["thumbnail"],
      description: video["description"]
    }
  end
end
