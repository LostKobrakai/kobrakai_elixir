---
title: Data to Responses
tags:
  - blog
  - programmierung
  - backend
language: EN
excerpt: |
  Phoenix 1.7's HEEx introduces new HTML rendering patterns, but under the hood, much remains unchanged—understanding these lower-level primitives clarifies how data becomes HTTP responses.
---

The introduction of HEEx in Phoenix 1.7 and the shift toward rendering HTML with
function components brought significant changes to how data is transformed into
HTTP responses in Phoenix. However, most of these changes were at the surface
level. Under the hood, many mechanisms remained unchanged and are still largely
backwards compatible. In this blog post, I'll explore some of Phoenix's
lower-level primitives to clarify how they work, even as the interfaces for
using them evolve.

## Selection

To start, consider this scenario: We have a controller and some data it has
loaded. What do we need to send a response to the HTTP request we received?

1. We need the data to be sent.
2. We need to format the data into a format we can return in an HTTP response.
3. We need to decide on a function that will handle the data-to-format
   conversion. Usually that function is identified by a name, but since Elixir
   organizes functions within modules, the module is also a consideration.

Before Phoenix 1.7, that selection followed this convention:

```elixir
MyAppWeb.ResourceView.render("name.format", assigns)
#        ^                    ^    ^        ^
```

Phoenix 1.7 changed the default convention to:

```elixir
MyAppWeb.ResourceFORMAT.name(assigns)
#        ^       ^      ^    ^
```

All the same pieces of data remain, just encoded differently. The primary
difference is that the former convention allowed multiple formats to be
transformed within a single module. This is still possible to configure manually
in Phoenix 1.7, but not using the default inferred naming convention.

The new convention however aligns with the calling conventions of function
components of `Phoenix.Component` using the HEEx template engine.

### Name

We typically call `Phoenix.Controller.render/3`, where `name` and `assigns` are
provided. Before Phoenix 1.7, `"name.format"` was common, though atom names were
always an option.

```elixir
render(conn, :index, posts: posts)
# render(conn, "index.html", posts: posts)
```

### Formats

Formats are negotiated from the request's `Accept` headers and processed by the
`Phoenix.Controller.accepts/2` plug found in most router pipelines. The plug
reads the request header and, given a list of available formats for a route,
selects the most suitable format for the response. This process may fail if
negotiation cannot select an appropriate format. Consult the function's
documentation for details about when this might occur.

`Phoenix.Controller.put_format(conn, :html)` can be used to explicitly set a
format, bypassing content type negotiation.

### (View) Modules

The module to use is typically inferred from the controller's name. For example,
`MyAppWeb.PostController` would retain the prefix `MyAppWeb.Post` and determine
the related module from there.

This used to be `MyAppWeb.PostView`, but starting with Phoenix 1.7, the default
changed to `MyAppWeb.PostFORMAT`.

This logic and mapping is controlled by the `:format` option in `use
Phoenix.Controller` (starting with Phoenix 1.7) as well as
`Phoenix.Controller.put_view/2`. The former controls how a controller's default
mapping works, while the latter can be used wherever plugs are implemented to
override inferred values with specific modules.

Previously, there was only a single view module, but with the format now encoded
in the module name, views in Phoenix 1.7 can be defined per format as well.

```elixir
put_view(conn, MyAppWeb.CustomView)
put_view(conn, html: MyAppWeb.CustomViewA, json: MyAppWeb.CustomViewB)
```

### Assigns

There's not much to be said about assigns, but it's the fourth piece of
information related to calling view module functions. It provides the data to be
converted.

With that, the selection part is complete. However, the functions being called
also need to be defined.

## View Functions

View functions need to be defined to transform the passed `assigns` into a
response that can be sent back via HTTP.

First, let's examine the "function definition" portion. There are two approaches:

### Manually defined

View functions can always be defined manually in a view module. Regardless of
whether selection follows pre or post-Phoenix 1.7 conventions, a function or
function head can always be manually defined.

```elixir
def index(assigns) do
  ~H"""
  …
  """
end
```

### Templates

The alternative approach is using templates. Templates are external files that,
at compile time, are loaded, converted to functions, and added to the module
that loaded the template.

This functionality is—and has always been—contained in `Phoenix.Template`. The
`phoenix_template` package can even be used independently from Phoenix for this
purpose.

Since Phoenix 1.7, `embed_templates` has become the preferred API for embedding
templates into a module. This function is also mirrored in `Phoenix.Component`
within `phoenix_live_view` for those wondering—it's the same function.

```elixir
embed_templates "posts/*"
```

Templates are commonly named following the pattern `name.format.engine`. Before
1.7, the format was essential because it became part of the function definition
for selection. Now it serves primarily as documentation.

#### Template Engines

The last part of the template name is the engine. But what exactly is an engine?

Engines are implementations of the `Phoenix.Template.Engine` behaviour, which
has a single `compile/2` callback that converts a file path and template name
into AST for a function body.

By default, template handling includes both an EEx engine
(`Phoenix.Template.EExEngine`) and an Elixir scripts-based engine
(`Phoenix.Template.ExsEngine`). `phoenix_live_view` adds the HEEx engine to
these options. Engines and their mapping can be customized through configuration.

That covers the two ways of defining functions. But what do these functions
return? An HTTP response can only contain text, so binary or iodata would be
the only sensible options. However, we rarely return these directly from view
functions. Instead, we return whatever the `~H` sigil produces or plain Elixir
maps when data is intended to become JSON.

There's one final piece to consider.

### Format encoders

Format encoders define how the return values of view functions are converted
into iodata to send in the HTTP response. By default, there are two encoders
applied across three formats.

#### `Phoenix.HTML.Engine` for `:html` and `:js` format

The implementation uses the `Phoenix.HTML.Safe` protocol (defined in
`phoenix_html`) to transform safe HTML to iodata. This is how Phoenix ensures
that only properly encoded (or explicitly forced) markup appears in responses.

This mechanism also enables various data types to be transformed into HTML
within Phoenix. For example, `phoenix_live_view`'s `~H` returns structs that
implement this protocol.

The module also defines the `EEx` based engine used as a template engine for
html – hence the naming. Format encoders and template engines can sometimes
be closely related.

#### `json_library()` for `:json` format

For JSON data, Phoenix delegates to the `encode_to_iodata!/1` callback of the
configured JSON library. This means the data returned by a view function is
directly passed to that JSON library for encoding.

As with template engines, formatters and their mapping can be customized through
configuration. In the past, I've used this capability to return structured XML
data from view functions and let a format encoder convert it into actual XML.

With this, we've covered the entire path from a controller with data to render,
all the way to having iodata ready for the HTTP response. There are valuable
opportunities for customization in your own applications, and this knowledge
should demystify the changes introduced in Phoenix 1.7 as well as any future
developments.

---

There's one topic I've deliberately avoided discussing until now though:

## `Phoenix.View`

Phoenix before 1.7 included `Phoenix.View` (now available as a separate library
called `phoenix_view`). The reason it was removed in version 1.7 is quite
reasonable: it wasn't essential. Most of what it did was establish the
convention we examined earlier:

```elixir
render("name.format", assigns)
```

All the template handling has always been delegated to `Phoenix.Template`.

Since that convention is no longer the default, `Phoenix.View` serves little
purpose. Many of its helpers are now better implemented by calling other
functions with the new convention directly. It's still useful for backwards
compatibility, but beyond that, it's not particularly worth exploring.
