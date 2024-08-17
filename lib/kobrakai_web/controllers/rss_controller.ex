defmodule KobrakaiWeb.RssController do
  use KobrakaiWeb, :controller
  alias Atomex.{Feed, Entry}
  alias Kobrakai.Blog

  def rss(conn, _) do
    send_resp(conn, 200, build_feed(conn, Blog.all_posts() |> Enum.reverse()))
  end

  def build_feed(conn, posts) do
    Feed.new(url(conn, ~p"/"), DateTime.utc_now(), "Kobrakai")
    |> Feed.author("Benjamin Milde", email: "benni@kobrakai.de")
    |> Feed.link(url(conn, ~p"/feed.xml"), rel: "self")
    |> Feed.link(url(conn, ~p"/"))
    |> Feed.subtitle("Written by Benjamin Milde")
    |> Feed.icon(url(conn, ~p"/images/signee.png"))
    |> Feed.entries(Enum.map(posts, &build_post(conn, &1)))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp build_post(conn, post) do
    {:ok, datetime} = DateTime.new(post.date, ~T[00:00:00])

    Entry.new(url(conn, ~p"/kolumne/#{post.id}"), datetime, post.title)
    |> Entry.content({:cdata, post.body}, type: "html")
    |> Entry.build()
  end
end
