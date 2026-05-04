---
title: ElixirKit ↔ OIDC
tags:
  - blog
  - programmierung
  - backend
language: EN
excerpt: |
  How to combine an elixirkit desktop app with OIDC
---

At work we had been using [elixirkit](https://github.com/livebook-dev/elixirkit)
for a small menu bar app some time last year. Copying livebook's usage of elixirkit
at the time brought us quite quickly to a working proof of concept for the
local network proxy we needed. Recently we were looking into adding some
authentication to the app to move it closer to being ready for real usage beyond
just being a PoC – and given we've been exploring OpenID Connect lately as well
I wanted to combine those pieces.

## ElixirKit using tauri

There wasn't just OIDC to be added though. ElixirKit started out as a bridge
between elixir and individual swift and C# codebases for the desktop specific
parts. That's what we had used some time last year. Since then elixirkit was
updated to integrate with [tauri](https://tauri.app/) instead and was actually
released as a standalone mix package. I won't go into more details on that portion,
but make sure to check the package out now that it's more approachable to check out.
There's an example document, which was easy to follow and set me up with something
working quite quickly.

## OIDCC

With elixirkit tauri doesn't render a javascript based static/spa website, but
it starts an elixir project alongside the desktop app where one can run e.g. a
phoenix server to serve pages to the desktop app. For adding OIDC I therefore
was able to stick to the tools I had already been using in other projects:

The awesome oidcc / oidcc_plug packages are provided by the [EEF](https://erlef.org/).
The implementation is certified OIDC compatible, and the package features secure
defaults, but can also be customized where providers eventually have different
opinions on how things are supposed to work in detail. Having used oidcc with
phoenix before I knew I wanted to use it in this use case as well.

By default an OIDC login works by a website redirecting the user to an identity
provider. That redirect includes various details to secure the flow and an
`redirect_url`. The identity provider then handles authentication of the user.
When successful the identity provider redirects the user back to the application
using that provided `redirect_url`. The identity provider also adds some details
to the redirect including an id token and an access token when for fetching
additional information about the user.

On a desktop app, even if essentially just being a separate website viewer, there
are a few implications of that flow to deal with.

### Single sign on

OIDC often includes single-sign-on. So if a user already has an active session
with the identity provider, they do not need to log in and are directly forwarded
back to the application they want to log in on. On a custom desktop application
the likelihood of the webview already having an active session is essentially zero.
So we want users to log in using the session of their local default browser, not
the webview of the application.

At the time oidcc_plug did fully take over the request cycle around forwarding
to an identity provider, which made it do exactly what we do not want – the
webview would open the identity providers login screen. After a simple
[PR](https://github.com/erlef/oidcc_plug/pull/81) however it's now possible to
configure the plug, so all the preparation and crypto is still done by oidcc_plug,
but the user can handle the redirect.

But what needs to happen instead of the default respond with a redirect on the
current http request:

With elixirkit one gets a PubSub connection to tauris rust backend. So the
url to redirect to can be sent there, where the
[tauri-opener](https://v2.tauri.app/plugin/opener/) plugin can then open the
url in the default browser on the users operating system.

The http request the application received can respond with some html telling the
user to complete the login on their browser given it won't do the redirect itself.

### Redirect back

Given the users browser is now used to login, it'll therefore also trigger the
redirect to the provided `redirect_url`. What would that `redirect_url` look like
for a desktop application though? [RFC 8252](https://datatracker.ietf.org/doc/html/rfc8252#page-7)
has some answers on that question. It mentions 3 approaches - I'll only go into
the two most applicable ones.

#### Redirect to loopback address

One way the desktop application can be targeted by the users browser is by opening
a port on localhost / the loopback interface of the user, which the users browser
can open. With our phoenix application we're already having an endpoint on the
users loopback interface that serves the desktop app itself. So for the OIDC
redirect back we simply add an additional route.

That route will be hit in the context of the users browser though. All the data
we need to validate the redirects validity by is stored on the session of the
desktop apps webview though - when using oidcc_plug. This hurdle can be solved in
many ways given it's moving data between various places on the same desktop app.

The path I chose was using elixirkit's pubsub again to make tauris rust backend
navigate the webview to the url, where oidcc_plug would pick up the data sent
by the identity provider, validate it and provide it on the auth controller –
just like it happens in a non-desktop-app context.

Here again I made the request triggering the pubsub message just respond with
some static text, telling the user that the redirect was successful and they
should switch back from the browser to the desktop application to continue.

##### Random port

The RFC mentions this explicitly, but you want that for an elixirkit app
anyways: Using a random port for the phoenix server instead of a hardcoded one.
If you configure `http: [port: 0]` on your phoenix endpoint it'll listen on a
random free port provided by the operating system. With
`MyAppWeb.Endpoint.server_info(:http)` you can query for the selected port at
runtime.

If you have worked with OIDC before you might wonder how that works when identity
providers validate `redirect_url`s against a preconfigured set though. The RFC
also answers that question: When providing a url using loopback interfaces
(`localhost`, `127.0.0.1`, `::1`, …) identity providers are expected to validate
a url even if the port is different. So when creating an OIDC application at an
identity provider you can skip a port and it should still validate and work.

#### Deep links

Another approach to send data over the chasm between the users browser and
the desktop application are deep links. They're custom scheme urls (`myapp://…`),
which operating systems implement in a way when opened they're triggering some
application – kinda like earlier we made opening an `https` url be handled
by the default browser.

Tauri also has a [plugin for handling those deep links](https://v2.tauri.app/plugin/deep-linking/).
When that plugins callback is called it can also either navigate the webview of
the app or do whatever means you might use to make the webview complete the OIDC
flow.

This approach has a few downsides. You can find all of them in the docs for the
plugin, but for me the most important one is a limit of macos. It allows deep
linking only for applications installed under `/Applications`. Given deep links
are essentially a global registry for `app-scheme` -> `Application` this kinda
makes sense, there are also security considerations to include, … It however also
means just starting a plain dev build of the tauri app won't receive any deep
links. For me that meant I also implemented the previous approach, after having
tried this one first.

There's still reasons for this approach as well though. When using deep links
identity providers know that the other end of the flow is a desktop app and can
cater to that. E.g. Microsoft Entra ID does shows different texts to users.

Also deep links do not open on the users browser similarly to e.g. file downloads,
but directly bring the application into the foreground. No need for the user to
manually switch back to it.

### Security - or "This is not a server"

#### PKCE

There are a handful of ways an OIDC client can authorize against an identity
provider to be allowed to receive data back after a user authenticated. The
big differentiator when selecting one of those options is if the client can be
trusted. For server side applications this is usually true and using
client_id/client_secret pairs or certificates are common. For desktop applications
that's not the case. There's no way for a desktop application to fully keep
secret what it has access to. So when registering an OIDC application to be
used with a desktop app the flow to be used should be the PKCE flow.

PKCE is a bit like CSRF in that it makes sure the client having started the
flow is the only one able to complete it, even if it could be any client, which
happens to know the client id related to the OIDC application. Kinda like CSRF
makes form submits not triggerable by third parties.

#### Data Storage

The other security concern is what to do with access tokens or refresh tokens.
For browser the advice is usually to never store those in e.g. local storage
because they're not very protected there. For a desktop application the whole
app including the elixir side starts out like that. You could leave those tokens
just in memory, but that means reauthenticating each time when opening the app.

I've not yet deeply evaluated my current solution for that portion, but
for now I've addressed this one by using rusts keyring crate to store an
encryption key in the operating systems keyring and deriving an sqlite
encryption key and phoenix secret key from that. If no secret exists it's created.

That way the data is secured at rest and only accessible when the users keyring
is unlocked.

---

I hope that knowledge is useful to anyone. If there's any additional insights or
things I should be aware of please let me know. This is my first foray into
desktop applications in a more serious context. I also want to shout out
[@maennchen](https://github.com/maennchen), who's been doing much of the security
work for the [EEF](https://erlef.org/) and who wrote oidcc, so our applications
can be secured well with OIDC.
