---
title: "Phoenix Views for JSON APIs"
tags: 
  - blog
  - programmierung
language: EN
excerpt: |
  Why the phoenix view layer might be the better way to convert data to json.
---

When doing JSON APIs in phoenix one will eventually hit the fact that by default
structs cannot be encoded to json by `Jason`, the default json library of phoenix.

Looking at the README of `Jason` this is quickly resolved by doing something like 
this: 

```elixir
defmodule User do
  @derive Jason.Encoder
  defstruct [:id, :name, :title, :coordinates]
end
```

This does work, but it also has quite a drawback: Protocol implementations are
module based and therefore global. One cannot have a given struct encode to 
multiple different json representations. This might not sound that problematic
at first, as one usually hits that problem trying to get the struct to convert
to the first json form required in a project &ndash; though that might not stay
to be the only one.

## Changing requirements

The `User` struct of the past section could be used in multiple parts of an 
application. Let's consider the application holding a blog, which users can publish on, 
and also a map of registered users to find people by location. Both should be powered
by individual api endpoints. 

By implementing `Jason.Encoder` the users can be encoded to json directly in the 
controller:

```elixir
# BlogController
def index(conn, _) do
  json(conn, %{authors: Users.list_users()})
end

# MapController
def index(conn, _) do
  json(conn, %{users: Users.list_users()})
end
```

This will encode all users to json, but including all struct fields on both endpoints, 
even though only the blog is concerned about titles and coordinates only being relevant
to the map component. 

If we want to remove the `:coordinates` field from the authors this would be possible 
by adjusting how the `Jason.Encoder` implemenation works. Though it would remove 
the coordinates for the map's users list as well. Additionally it's not great to need
to adjust a core business logic module to cater to a need of the web api.

## Phoenix Views

A great solution to the problem here is using the phoenix view layer instead of
the `Jason.Encoder` protocol. Often the view layer of phoenix is seen as a part
only needed for HTML based websites or even more specific for handling templates,
but the view layer is very useful even beyond those use-cases.

The phoenix view layer has two important pieces to it. The template engines 
(.eex, .exs, .leex, .heex, …), which turn template files into functions on the 
view module &ndash; not so important here &ndash; and format encoders. Format
encoders turn the values returned by `MyAppWeb.SomeView.render/2` functions
into iodata to send back as the http response.

That's how a map returned from such a function is turned into a json string
if the format is `.json` or how for `.html` the html encoding is applied. One
can even add custom format encoders (e.g. for `.xml` or `.mjml`).

## Rendering JSON

How would using the phoenix view layer look like for our example. Let's start 
with a view module for each of the controllers.

```elixir
# BlogView
def render("index.json", %{authors: authors}) do
  %{
    authors: render_many(authors, __MODULE__, "author.json", as: :author)
  }
end

def render("author.json", %{author: author}) do
  %{
    id: author.id, 
    name: shorten_firstname(author.name), 
    title: author.title
  }
end

defp shorten_firstname(name) do
  [first, rest] = String.split(name, " ", parts: 2)
  <<letter::binary-size(1), _rest>> = first
  "#{letter}. #{rest}"
end
```

This shows not only how the returned fields can be limited, but also how the
format of a field can be adjusted to what needs to be returned. Using views
for converting the struct to the returned map of data provides a lot of flexibility
and also a place to segment such endpoint specific implementation details into.

This not only prevents controllers to get more complex, but also view modules
can be used by multiple controllers. So composition and reuse is supported.

```elixir
# MapView
def render("index.json", %{users: users}) do
  %{
    users: render_many(users, __MODULE__, "user.json", as: :user)
  }
end

def render("user.json", %{user: user}) do
  %{
    id: user.id, 
    name: user.name, 
    coordinates: user.coordinates
  }
end
```

This one shows the map view. There doesn't seem to be much new here, but consider
that the coordinates are just returned as is, even if in a real world implementation
it's likely a struct as well. 

Using the view layer makes most sense for domain models of an application. 
Auxiliary structs, which mostly represent complex values like coordinates or 
`Decimal` structs still benefit from global `Jason.Encoder` implementations given
there's hardly any use in encoding just parts of the data they hold. Those structs
are more akin to a single value represented by a struct of details and less a
container of multiple distinct pieces of data.

## Takeaway

Phoenix views are generally a great way to handle the transformation from 
application level data to an exchange format sent to other parties. It's kind of
the inverse of `Ecto.Changesets`, which bring data into a system, while views
provide data to the outside. Both are in my opionion nice ways of forming an so 
called anti-corruption layer in an application to separate the outside world 
from core data formats and making outside change easier to handle.

Starting with phoenix 1.6 [the view layer got extracted](https://github.com/phoenixframework/phoenix_view) from phoenix the framework, 
so it can be included wherever useful, similar to how ecto can be useful even
without a database.