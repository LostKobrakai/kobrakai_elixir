---
title: "One-to-Many LiveView Form"
draft: true
tags: 
  - blog
  - programmierung
  - frontend
language: EN
excerpt: |
  How to make a one-to-many relationship editable with a LiveView powered form.
---

With Phoenix LiveView becoming more and more popular people try to build more 
dynamic forms than before. Often this involves forms, which allow editing 
a parent schema and a one-to-many relationship, where inputs are dynamically 
added and removed. For example consider a invoice schema, which can have many 
rows added.

There are however a few foot-guns when approaching forms like that. We'll b



The introduction of [HEEx and function components](https://hexdocs.pm/phoenix_live_view/0.17.9/Phoenix.Component.html) to Phoenix LiveView brought a lot of improvements for 
building and maintaining UIs in html to the Phoenix community. A simple example 
of a function component would be extracting a common chunk of markup to be reused. 

```elixir
defmodule Components do
  use Phoenix.Component

  def alert(assigns) do
    ~H"""
    <div class="alert">
      <h3 class="alert__title"><%= @title %></h3>
      <p class="alert__body"><%= @body %></p>
    </div>
    """
  end
end
```

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Document</title>
</head>
<body>
  <.alert title="Attention" body="Something went wrong!" />
</body>
</html>
```

That approach works great for abstracting markup and making templates more expressive.
But it's only useful to a project interested in this specific markup. I think a 
lot of the frustrations of people with frameworks like bootstrap came from the fact
that it sounds nice to share components, but as soon as it comes to customizations
it's easy to get into a big mess fast – especially where functionality and how things
look are coupled. It would be nice to not only be able to share implementations of 
components, but also to be able to create higher level components, which share logic and functionality, but without coupling it to markup yet.

### Going renderless

Components are considered "renderless" when they're not rendering any markup on
their own, but delegate rendering of information to how the user of the component 
considers it useful. This approach has been used in client side systems like
react or vue for a long time already, but with heex it's now usable within Phoenix
as well.

As an example consider a pagination component. Usually pagination is constraint 
only by a few datapoints, like e.g. `current_page` and `total_pages`. A function
component could transform those two values to all those many intermediate values
needed to actually render a pagination. Sometimes it just makes sense
to abstract (complex) functionality without coupling to a specific and fixed way
to render the data and having a gazillion options to pass around won't
make anybody happy. That's where a renderless component can help out.


```elixir
defmodule Components do
  use Phoenix.Component
  use Phoenix.HTML

  def pagination(assigns) do
    %{
      current_page: current_page, 
      total_pages: total_pages
    } = assigns

    lower_bound = max(1, current_page - 3)
    upper_bound = min(total_pages, current_page + 3)
    pages = lower_bound..upper_bound//1

    setup = %{
      is_first: current_page == 1, 
      is_last: current_page == total_pages, 
      pages: pages, 
      current_page: current_page, 
      total_pages: total_pages
    }

    assigns = assign(assigns, :setup, setup)

    ~H"""
    <%= render_slot(@inner_block, @setup) %>
    """
  end
end
```

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Document</title>
</head>
<body>
  <.pagination current_page={7} total_pages={20} let={setup}>
    <ul class="pagination">
      <%= unless setup.is_first do %>
        <li class="page-item">
          <%= link "«", to: Routes.some_index_path(@socket, :index, %{page: 1}), title: "Go to first" %>
        </li>
      <% end %>
      <%= for page <- setup.pages do %>
        <li class="page-item">
          <%= link page, to: Routes.some_index_path(@socket, :index, %{page: page}) %>
        </li>
      <% end %>
      <%= unless setup.is_last do %>
        <li class="page-item">
          <%= link "»", to: Routes.some_index_path(@socket, :index, %{page: setup.total_pages}), title: "Go to last" %>
        </li>
      <% end %>
    </ul>
  </.pagination>
</body>
</html>
```

This works great – though a critic might still say this can be done by precomputing
`assigns`.

There's however an interesting case where those renderless components really shine.

### Aria & Accessibility

For react there exists a quite interesting library called [downshift](https://github.com/downshift-js/downshift), which implements a autocomplete/combobox/searchable select
as a renderless component, while taking care of the necessary accessibility 
requirements to such a component, supplying necessary aria events to users to
add to their markup.

I don't yet see something like downshift coming to HEEx soon. It also deals with
event listeners and many of them should be handled on the client side with no
server involved.

What could be interesting however is having less interactive components be
supplied with proper aria markup, e.g. for validation errors on forms or open/closed
state on toggleable content.

I quickly toyed with something like this today and it's for sure an interesting idea
for making it easy to do the correct thing:

```html
<.form for={@changeset} let={f}>
  <.field_context form={f} field={:name} let={field}>
    <label for={field.id}><%= field.label %></label>
    <input 
      type="text" 
      id={field.id}
      name={field.name}
      class={["input", if(field.errors, do: "has-error")]}
      {field.input.aria} />
    <%= if field.errors do %>
      <p class="errors" {field.validation.aria}>
        <%= for error <- field.errors %>
          <span><%= error %></span>
        <% end %>
      </p>
    <% end %>
  </.field_context>
</.form>
```

As far as I know there's some work happening on form handling with live view by
the Phoenix team at this time. Maybe this can be a time to think not just about
how to update `phoenix_html` helpers to HEEx, but also go beyond that.