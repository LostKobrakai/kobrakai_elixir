---
title: "LiveView: Double Mount"
tags: 
  - blog
  - programmierung
language: EN
---

When using `phoenix_live_view` people are often worried about their LiveViews 
being mounted twice for fresh requests. I regularly see people asking for ways around
this fact or even why this is needed in the first place.

<!-- excerpt -->

## What causes the double mount?

A fresh request by an user to a website is always a plain http request. It hit's
`MyAppWeb.Endpoint` and is served by the plug based pipeline setup on the server.
LiveView's will be rendered in what is called "static render". That means
instead of starting a long running process any LiveView will run `mount/3` 
(+ `handle_params/3`) once and the resulting markup is rendered into the http 
response.

When the client received that response to the http request it'll run the `app.js`
and start connecting to the websocket endpoint for LiveView. This time any LiveView
will be started in a proper long running process, it will mount and render again
and the client side will replace (merge into) what it got from the http response.
After that the server knows which markup the client received (and which templates)
it got, so it can start doing its extensive diffing for subsequent changes to the dom.

Given the websocket connection can only start after the client did receive the initial
http response (and the javascript) it's quite obvious that there need to be at least
two steps. Browsers don't have means to directly start with the websocket connection.

After this one initial http request however one can use `live_redirect` and `live_patch`
to move from one LiveView enabled page to another without needing the http request.
Any changes can be transfered purely over the existing websocket connection, now that
it's established and the js for it resides on the client.

## TLDR: Can we avoid the double mount?

On the intial request: No, we can't.  
For subsequent request: See `live_redirect` and `live_patch`.

## Can we at least not fetch data twice?

This is more complex, as there are various layers to it.

First of all the initial http request and all its fetched data is long cleaned up
at the time the websocket connection connects to the server. So there's no way to 
share data between them directly. 

Then there's the `session` which allows sharing data from the plug pipeline of the
static render to any later render. The data of the `session` is transfered by 
placing it encoded within the html send as response by the http request. So it 
should not hold much information or it will bloat the http response. It's a solution
for passing around id's to certain things, which were already validated by the plug
pipeline, but not for bigger amounts of data. 

The only way to keep data around without sending it to the client is caching.

## Caching to the rescue?

It's still not a simple "yes".

As we've already seen an inital LiveView page's loading involves two connections
to the server. Therefore one shouldn't try to treat them like one request, but 
it's much more similar to an user requesting an non LiveView page and then 
immediately hitting refresh. This analogy will bring up some important considerations 
for the time the first of those requests might want to cache data.

- _Will the reload happen? a.k.a. Will the LiveView js connect (to this node) at all?_  
  There could e.g. be a problem with loading the javascript for liveview.  
  In a distributed setup it could just be the load balancer routing the request
  to different nodes.

- _When will the reload happen? a.k.a. When will the LiveView js connect?_  
  The user could be on a slow network and the websocket connection will only succeed minutes later.

There's also another point for LiveView specifically:

- _How should reconnects be treated?_  
  From the servers perspective a first websocket connection within seconds
  of the http requests looks exactly the same as a connection being done
  half an hour later because the websocket connection dropped shortly.

So the answer if caching helps really depends.

## Bonus: Skip doing expensive fetching in the static render

One way to avoid the whole problem of fetching expensive data twice is not 
fetching and therefore rendering that data on the initial static
render and instead e.g. rendering some loading spinner or similar. On the
mount via the websocket connection the actual data would then be loaded.

This has the downside that any issue preventing the websocket connection will
mean that content is not being available to the user. This is similar to e.g.
the consideration in a traditional SPA context.