---
title: Customize Phoenix.View EEx rendering
tags: 
  - blog
  - programmierung
language: EN
---

Getting straightforward HTML templates rendered in Phoenix is really easy. Create a plain `View` module (see [here](https://hexdocs.pm/phoenix/views.html#rendering-templates) if you don’t know how), add the related `.eex` templates, and it just works. What if you need slightly more customization to render your templates? Maybe you need more than a single [“layout” template](https://hexdocs.pm/phoenix/controllers.html#content) or you want to render a different partial depending on values in the `assigns` map. In such cases you can use the `render/2` function in your view module.

If you’ve read the Phoenix Guides you’ve probably already seen examples of the `render/2` functions in `View` modules. They’re used when JSON data needs to be rendered.

```elixir
defmodule HelloWeb.PageView do
  use HelloWeb, :view

  def render("index.json", %{pages: pages}) do
    %{data: render_many(pages, HelloWeb.PageView, "page.json")}
  end
  
  […]
end
```

You can do something similar for your HTML templates as well, but you cannot simply return a map of data like in the above example. You will want to render the template within your customizations. For that you can use the private function `render_template/2`([docs](https://hexdocs.pm/phoenix/Phoenix.Template.html#module-rendering)) of your `View` module.

```elixir
defmodule HelloWeb.EventView do
  use HelloWeb, :view

  def render("show.html", %{event_status: status} = assigns) do
    template = 
      case status do
        :public -> "public.html"
        :presale -> "presale.html"
        :past -> "bygone.html"
        _ -> "not_public.html"
      end
      
    render_template template, assigns
  end
end
```

`render_template/2` is the actual function to render a template file. If you don’t add your own `render/2` function, then this function is called behind the scenes. Using this function you’re now free to compose how exactly you’d like your template files to be rendered. E.g. in the above example there wouldn’t even need to be a `index.html.eex` because the template is replaced by different ones depending on the event’s status.

Another example is the need for composed “layout” template in phoenix. In an imaginary application there’s the admin layout and the customer facing one. Without any customization one would have a `app.html.eex` and a `admin.html.eex`, which is totally fine. But in a case where both layouts share the whole `<head>` setup as well as the linked javascript files changes would need to be duplicated in both files. Ideally there would a `wrapper.html.eex` for the outer html and `app.html.eex` / `admin.html.eex` would only hold the actually different markup for headers or footers.

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">

    <title>Hello!</title>
    <link rel="stylesheet" href="<%= static_path(@conn, "/css/app.css") %>">
  </head>

  <body class="helvetica">
    <%= render_template @layout_template, assigns %>
    <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
  </body>
</html>
```

```html
<header>App View</header>
<main role="main">
  <%= render @view_module, @view_template, assigns %>
</main>
<footer>&copy; SomeApp</footer>
```

```elixir
defmodule HelloWeb.LayoutView do
  use HelloWeb, :view
  
  @wrappedLayouts ["app.html", "admin.html"]

  def render(template, assigns) when template in @wrappedLayouts do
    render_template "wrapper.html",
      Map.put(assigns, :layout_template, template)
  end
end
```

Here `render_template/2` is used within the `wrapper.html.eex` to render any template supplied via `:layout_template` just like they have been rendered automatically before. But there’s no more need to duplicate the whole `<head>` section or any of the appended scripts in those templates. That’s all keep in the single place of the `wrapper.html.eex`.