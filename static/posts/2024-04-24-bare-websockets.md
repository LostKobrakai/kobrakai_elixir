---
title: Bare Websockets
tags: 
  - blog
  - programmierung
  - backend
language: EN
excerpt: |
  Adding a bare websocket server to plug/phoenix.
---

While phoenix used websocket connections for a long time for its 
`Phoenix.Channel` abstraction there wasn't really a good way to use websocket 
directly up until phoenixs latest major release (1.7). 

Before that release working with bare websocket connections meant directly calling 
into the underlying webserver beneight phoenix – `:cowboy` or more recently `Bandit`. 

Before 1.7 the implementation for channels within phoenix also directly integrated
with `:cowboy`, so there wasn't really a way for `Bandit` to replace cowboy as an 
alternative webserver completely. So Mat Trudel (the creator of `Bandit`) stepped in 
and together with the phoenix/plug team build out all the necessary new abstractions 
to make it possible for `Bandit` to power websockets and therefore channels as well. 

## New Abstractions

The result of that work have been two new libraries, both now maintained by the 
phoenix team:

- `WebSock` – This library includes just a behaviour for handlers of a websocket 
connection. The equivalent for http would be the `Plug` behaviour.
- `WebSockAdapter` – This library includes the actual implementations for upgrading 
a http connection to a websocket connection for webservers (currently `:cowboy` and 
`Bandit`), which use `WebSock` handlers. The http level equivalent here would be `PlugCowboy` 
or the included plug integration of `Bandit`.

With all the low level bits taken care of it doesn't take much more code to make 
use of that in a phoenix or plug application. 

## Upgrading a http request

`WebSockAdapter` does directly integrate with `Plug`, so any applicable request
`conn`s can be upgrated using `WebSockAdapter.upgrade/4`. This doesn't need to be
called in any special place – contrary to the `Phoenix.Endpoint.socket/3` macro,
which only works in endpoints. This means a request can be routed by routers,
run through authentication plugs or whatever necessary before being upgraded.

Be aware that websocket requests do have distinct constraints to http though, so
be sure to inform yourself when trying to implement any security features. There
are valid reasons why e.g. you cannot access cookies and you might want to deal 
with the `check_origin` config for phoenix channels.

To add a custom websocket endpoint into phoenix we'll be using a plug, that's 
then added to the apps router:

```elixir
defmodule MyAppWeb.WebsocketUpgrade do
  @moduledoc """
  Plug to upgrade request to websocket connection and starting `WebSock` handler.
  """
  @behaviour Plug

  @impl Plug
  def init(handler), do: handler

  @impl Plug
  def call(%Plug.Conn{} = conn, handler) do
    conn
    |> WebSockAdapter.upgrade(handler, %{path_params: conn.path_params}, [])
    |> Plug.Conn.halt()
  end
end
```

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  […]

  scope "/ws", MyAppWeb do
    get "/connection_timer/:name", WebsocketUpgrade, MyAppWeb.ConnectionTimer
  end
end
```

This is pretty straight forward. The plug takes the handler as an plug option,
and it's then forwarded to the websocket upgrade in the plug body. The 3rd parameter
for the upgrade is the initial `state` passed to the handler and the last one
allows for passing some options for how the webserver should deal with the connection.

The `upgrade/4` call itself as well as the webserver implementations will make 
sure only actual websocket connection requests will be upgraded. So no additional
checks needed. But you can use `WebSockAdapter.UpgradeValidation.validate_upgrade/1` 
to manually use the checks `WebSockAdapter` does e.g. if you want to know if a 
request is a websocker request in advance of doing the upgrade.

## The websocket connection handler

Once the http connection is successfully upgraded the handler takes over. It 
needs to implement the `WebSock` behaviour to handle sending and receiving data 
on the connection.

As an example this server will provide information around how long a connection
has been open and it does so automatically as well as when explicitly requested.

There are three required callbacks and two optional ones to implement. For the
optional ones please refer to the [`WebSock` documentation](https://hexdocs.pm/websock/0.5.3/WebSock.html).

- `init/1` – Received the state passed from the http upgrade. In this case it
receives path parameters from the initial `conn`.
- `handle_in/2` – Handle incoming websocket messages.
- `handle_info/2` – Handle elixir messages.

All callbacks may return messages to be sent to the client to complete
the bi-directional nature of a websocket connection.

```elixir
defmodule MyAppWeb.ConnectionTimer do
  use MyAppWeb, :verified_routes
  @behaviour WebSock

  @impl true
  def init(%{path_params: %{"name" => name}}) do
    path = ~p"/ws/connection_timer/#{name}"
    schedule_alert()
    {:ok, %{start: now(), path: path}}
  end

  @impl true
  @spec handle_in(any(), any()) :: {:ok, any()} | {:push, {:text, <<>>}}
  def handle_in({"request_timer", opcode: :text}, state) do
    {:push, {:text, "Connected to #{state.path} for #{diff(state.start)}s."}, state}
  end

  def handle_in(_, state) do
    {:ok, state}
  end

  @impl true
  def handle_info(:alert, state) do
    schedule_alert()
    {:push, {:text, "Alert for #{state.path} after #{diff(state.start)}s."}, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  defp now, do: System.monotonic_time()
  defp schedule_alert, do: Process.send_after(self(), :alert, :timer.seconds(15))
  defp diff(start), do: System.convert_time_unit(now() - start, :native, :second)
end
```

This is a short implementation, which sends back a message when receiving 
a `"request_timer"` message, as well as sending a similar one ever 15 seconds 
automatically (to show of the usage of `handle_info`). 

## Interactive Example

<!-- [KobrakaiWeb.Websocket] -->

## Comparison to `Phoenix.Channel`s

The above certainly is a bit more low level than `Phoenix.Channel`s, but also 
on first glance not that different. Therefore a reasonable question is why one
would use one or the other.

A plain websocket connection is very simple. It allows a client and server to 
exchange binary or text messages. That's it. Any websocket supporting client can
connect and start sending messages.

`Phoenix.Channel`s are quite a bit more than that. They extend the pubsub functionality
of `Phoenix.PubSub` to clients external to the elixir server(s) hosting it. 
So you get a bunch of semantics around how and with whom to share messages out of the
box with channels. Channels also come with predefined message formats on the wire, where
it actually doesn't even matter what transport powers the "wire". Could be websocket,
but could be many other protocols. These differences however mean that the client 
needs to understand that encoding and generally also wants to understand the pubsub 
nature and what topics mean in a channels context. That's what you need `phoenix.js`
for on a phoenix website to talk to channels.

Comparing this to other ecosystems it might be comparable to sockets.io, which
also uses a custom message protocol on top of different transport layers 
including websockets.

So to me there are two reasons for using bare websockets on a phoenix project:

- The client does only support websockets, but nothing higher level can be added on top
- The pubsub nature of channel is not actually needed or useful for the provided functionality

Additionally this allows for websockets on plain plug applications as well, where
channels aren't available in the first place.