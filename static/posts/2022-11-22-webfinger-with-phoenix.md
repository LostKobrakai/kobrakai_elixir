---
title: Serve the webfinger protocol with phoenix
tags: 
  - blog
  - programmierung
  - webfinger
  - phoenix
language: EN
excerpt: |
  Use webfinger to host your mastodon identity on your own domain
---

With Elon Musk taking over Twitter many, especially tech savvy, people have been 
looking at [Mastodon](https://joinmastodon.org/de) as an alternative – and so
did I. Mastodon is a federated platform, where you join as a user of a certain
instance, like for example [hachyderm.io](https://hachyderm.io/), the instance 
I joined a few days ago.

So people can now find me under the account name `@lostkobrakai@hachyderm.io`.

So far so good, but it kinda rubed me the wrong way to be `@lostkobrakai` of some 
random Mastodon instance. What if it goes away, will people still find my profile?
In the end these instance often depend on volunteers, which are in my opinion
not to blame if they would like to move on or stop doing what they do today.
However I'd really like to have my profile be linked to my own domain, even though 
I don't run my own instance (yet?).

Luckily that's actually rather simple to do as 
[explained to me](https://elixirforum.com/t/mastodon-handles-lets-share-them/29514/67?u=lostkobrakai) 
when I asked on the ElixirForum.

## Webfinger

The answer is webfinger – a http based protocol to "to discover information about 
people or other entities on the Internet"[^1]. 

The protocol works by having a known path on a website:

`GET /.well-known/webfinger`

That path can be queried with a `?resource=…` query string. Websites supporting
webfinger can return any suitable information they know about the resource in 
the JSON Resource Description (JRD) format, a standardized schema for 
data encoded as JSON. More details on it can be found in the RFC.

Given I recently moved my website to be powered by phoenix I did implement this
as a simple controller. 

I knew I wanted to have ETag support, so I pulled in `{:etag_plug, "~> 1.0"}` 
first and put that on the controller. ETags are a mechanism to skip sending
data when the client already has the data cached locally, which I hadn't really
touched much, so this was a good excuse to see how it goes.

```elixir
defmodule MyAppWeb.WebfingerController do
  use MyAppWeb, :controller

  plug ETag.Plug
end
```

Next the RFC for webfinger expects servers to return a `400`, if the request
misses the required `?resource=…` query parameter. I handled this one in a 
plug as well, though a custom one this time.

```elixir
defmodule MyAppWeb.WebfingerController do
  use MyAppWeb, :controller

  […]
  plug :resource_required

  defp resource_required(conn, _) do
    if conn.query_params["resource"] do
      conn
    else
      conn
      |> send_resp(:bad_request, "")
      |> halt()
    end
  end
end
```

Clients are also allowed to add filters using the `?rel=…` query parameter, but
I didn't implement supporting that feature. The RFC makes this optional, as the
server may just ignore those parameters and still work to the specification.

So the last thing to do is figuring out if our server knows about the requested
resource. This I handled in the controller action:

```elixir
defmodule MyAppWeb.WebfingerController do
  use MyAppWeb, :controller

  […]

  @aliases ["acct:lostkobrakai@kobrakai.de", "acct:lostkobrakai@hachyderm.io"]

  def finger(conn, %{"resource" => resource}) do
    case resource do
      r when r in @aliases ->
        data = %{
          subject: "acct:lostkobrakai@kobrakai.de",
          aliases: [
            "acct:lostkobrakai@hachyderm.io",
            "https://hachyderm.io/@lostkobrakai",
            "https://hachyderm.io/users/lostkobrakai"
          ],
          links: [
            %{
              rel: "http://webfinger.net/rel/profile-page",
              type: "text/html",
              href: "https://hachyderm.io/@lostkobrakai"
            },
            %{
              rel: "self",
              type: "application/activity+json",
              href: "https://hachyderm.io/users/lostkobrakai"
            },
            %{
              rel: "self",
              href: "https://kobrakai.de"
            },
            %{
              rel: "http://ostatus.org/schema/1.0/subscribe",
              template: "https://hachyderm.io/authorize_interaction?uri={uri}"
            }
          ]
        }

        response = Phoenix.json_library().encode_to_iodata!(data)

        conn
        |> put_resp_content_type("application/jrd+json")
        |> send_resp(200, response)

      _ ->
        send_resp(conn, :not_found, "")
    end
  end
end
```

As you can see I just hardcoded the values, but this could easily become more 
flexible when needed. One thing of note however is the returned content type of 
`application/jrd+json`. 

With phoenix we can do proper content type negotiation,
so in the router I didn't just add the router under the `:browser` pipeline, but
I created a custom pipeline:

```elixir
pipeline :webfinger do
  plug :accepts, ["jrd", "json"]
end

scope "/", MyAppWeb do
  pipe_through :webfinger

  get "/.well-known/webfinger", WebfingerController, :finger
end
```

The `"jrd"` format isn't known by the `:mime` application, so I've added the
necessary config to extend it as well. Make sure to recompile it using
`mix deps.compile mime --force`. Otherwise you might run into compile time errors 
around mismatched compiled and runtime configuration.

```elixir
config :mime, :types, %{
  "application/jrd+json" => ["jrd"]
}
```

With that everything is in place for me to be discovered under my own domain
as `@lostkobrakai@kobrakai.de`: 

https://kobrakai.de/.well-known/webfinger?resource=acct:lostkobrakai@kobrakai.de

This should allow people to find me without them needing to know which Mastodon
instance actually hosts my account at the time.

[^1]: [RFC 7033](https://www.rfc-editor.org/rfc/rfc7033)