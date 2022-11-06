---
title: Alternative parameters for phoenix controller actions
tags: 
  - blog
  - programmierung
language: EN
---
You probably know the default parameters of a phoenix controller action callback: `def index(conn, _params), do: […]` or `def create(conn, %{"entity" => entity_params}), do: […]`. This seems like a nice default when starting out working with phoenix. All you need to handle a request is the connection and its params after all, right? With me writing this post I obviously came to a different conclusion.

Quite early in a project of mine I noticed, that I handled most of the recurring tasks in plugs running before the actual controller action. For example the usual _Get an entity by its ID supplied as a url param_ is something I use a plug for instead of doing the `Context.get_entity(id)` call in all 4 actions of `show, edit, update, delete`. The results of those plugs are accumulated in the [`conn.assigns` map](https://hexdocs.pm/plug/Plug.Conn.html#module-connection-fields), so I can use them later on. This _use them later on_ is elegantly solved in views, because all assigns are available as `@entity` in templates, but that’s not the case for controller actions. At first is just felt like replacing `entity = Context.get_entity(id)` with `entity = conn.assigns.entity` lines, which didn’t really feel like much of an improvement. That’s something I wanted to deal with like with params: Pattern matching in the function head.

Luckily there’s a way in phoenix to make that happen by putting this into the controller module:

```elixir
def action(conn, _) do
  args = [conn, conn.params, conn.assigns]
  apply(__MODULE__, action_name(conn), args)
end
```

For a bit of technical background: You might already know that you can use [plugs in the body of a controller module](https://hexdocs.pm/phoenix/plug.html#function-plugs), but the controller by itself is also a plug. Using `use MyAppWeb, :controller` will make `Phoenix.Controller` setup the necessary callbacks for it being a plug.

Now when a controller is called by the router it’s not directly executing the action callback like `index/2` and others, but it’s executing the `call/2` function of the controller plug and that’s calling `action/2` of the controller (set up for us by default), which then in turn checks which action callback needs to be called. That function is overridable, allowing the user to modify how action callbacks are called (and if at all). This is what I did for the above code snippet.

With it in place my controllers mostly look similar to this:

```elixir
plug :entity_by_id when action in [:show, :edit, :update, :delete]

def edit(conn, %{"entity" => params}, %{entity: entity}) do
  with {:ok, entity} <- Context.update_entity(entity, params) do
    […]
  end
end

defp entity_by_id(%{params: %{"id" => entity_id}} = conn, _) do
  case Context.get_entity(entity_id) do
    %Entity{} = entity -> assign(conn, :entity, entity)
    _ -> not_found(conn)
  end
end
```

Using such a setup my controller actions usually don’t need to match anything out of the supplied params anymore while most do match something out of the assigns. All of the _setup_ work can be done in self contained plugs, while controller actions are mostly concerned with handling only the action that’s supposed to happen.

I’ve been using this in my work for a while now and it makes controller actions quite a bit cleaner and extracting things to a plug — even one local to the single controller — quite a bit more enjoyable. In new projects I usually put the snippet in the `my_app_web.ex` file, so any controller in the project works with such 3-arity actions. I’m not sure if this would ever find its way to be a phoenix default or the phoenix generators using plugs in their controller scaffold, but I feel it could make plugs and assigns quite a bit more approachable for beginners as well.