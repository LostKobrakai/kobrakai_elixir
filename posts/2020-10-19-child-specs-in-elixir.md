---
title: Child Specs in Elixir
tags: 
  - blog
  - programmierung
language: EN
excerpt: |
  Learn how to harness child specs and their elixir short forms to start supervisor children.
---

Child specs are often confusing for people trying to convert the old `Supervisor.Spec` based syntax to the newer child spec based syntax, people trying to integrate with erlang libraries or because they added more parameters to their `start_link` functions and now wonder why it fails when trying to supervise the process.

## Child spec map

To start, it's important to know what a child spec is. It's a map of data, which is used by supervisors to determine how they should start and interact with a certain supervised child. The format is documented in the `Supervisor` [docs](https://hexdocs.pm/elixir/Supervisor.html#module-child-specification) for elixir as well as the `:supervisor` [docs](https://erlang.org/doc/man/supervisor.html) for erlang, therefore I'll keep my explanations short. There are 6 keys: `:id`, `:start`, `:restart`, `:shutdown`, `:type` and `:modules`. Besides `:id` and `:start` the keys are optional with defaults.

The child spec for an run-of-the-mill `GenServer` essentially looks like this:
```elixir
%{
  id: Stack,
  start: {Stack, :start_link, [[:hello]]}
}
```

`:id` is the id the process will have as a child of a supervisor. Per `Supervisor` instance the id needs to be unique. `:start` is a `mfa()` tuple for what the supervisor shall call to start the child.

Up until here this is information applicable to both erlang and elixir. But elixir did build on top of child specs.

## Supervising children

In Elixir the change to child specs for configuring supervisor children was used to add standardized conveniences to that configuration. The idea here being to bring locality of information into the mix. 

Before the change a module `MyApp.Worker` would implement for example an `GenServer`, but the supervisor `MyApp.Supervisor` would need to configure the process being started as `type: :worker` and with `restart: :permanent`. This is ok'ish for processes you own the implementation for, but say the process comes from a library. If the library now needs to change and put the worker nested under an internal supervisor it's a breaking change because users of the library need to change to `type: :supervisor`. There's a disconnect between the source of truth for "What type of process am I?" and the code implementing the process.

I know of some (erlang) libraries, which implemented their own ways of returning a child spec map. Users could call a function with arguments, and get the full child spec in return. Elixir however took the idea and wrapped stdlib tooling around it. 

Instead of a list of child spec maps the elixir `Supervisor` can additionally deal with children being setup via a module name or a tuple of `{module_name, arg}`:

```elixir
children = [
  # Module only
  MyApp.Supervisor,
  # Tuple
  {Registry, keys: :unique, name: Registry.ViaTest},
  # One-off way to build a child spec map 
  :poolboy.child_spec(name, pool_args, worker_args),
  # Inline child spec map
  %{id: Stack, start: {Stack, :start_link, [[:hello]]}}
]
```

The additional options of a module or a tuple are stdlib means of doing a similar thing as the `:poolboy` example: 

- `{Registry, keys: :unique, name: Registry.ViaTest}` is a shortcut for `Registry.child_spec(keys: :unique, name: Registry.ViaTest)`
- `MyApp.Supervisor` is a shortcut for `{MyApp.Supervisor, []}` and therefore `MyApp.Supervisor.child_spec([])`

Both are ways of building a child spec map by calling `child_spec/1` on the respective module.

This is how an implementation of that function might look like:

```elixir
def child_spec(init_arg) do
  %{
    id: __MODULE__,
    start: {__MODULE__, :start_link, [init_arg]}
  }
end
```

## But what about `start_link` and why do I never see a `child_spec/1` functions?

The most common processes we interact with in elixir are build using `use Supervisor` or `use GenServer`. Both of them generate the needed `child_spec/1` automatically. It's overridable however if you need to alter the behavior.

### Updating the old `Supervisor.Spec`

The old way of configuring children looked like this: 

```elixir
children = [
  worker(MyWorker, [arg1, arg2, arg3]),
  supervisor(MySupervisor, [arg1])
]
```

The difference between `supervisor/3` and `worker/3` will be handled by the newly used `child_spec/1` function, so that becomes irrelevant knowledge to the supervisor itself.

However the `[arg1, arg2, arg3]` on both of the old functions meant it would start the process with `MyWorker.start_link(arg1, arg2, arg3)`. That's no longer the case with the automatically generated `child_spec/1` implementations. 

```elixir
children = [
  {MyWorker, [arg1, arg2, arg3]},
  {MySupervisor, [arg1]}
]
```

This will call `MyWorker.start_link([arg1, arg2, arg3])`. Instead of `start_link/3` `start_link/1` is called with a list. There are two ways to fix this: 

One is to manually implement `child_spec/1` for `MyWorker` altering the `:start` value – notice the missing square brackets.

```elixir
def child_spec(init_arg) do
  %{
    …
    start: {__MODULE__, :start_link, init_arg}
  }
end
```

The other is to modify `MyWorker` to have a `start_link/1` function, which can handle the list inputs.

## Do I even need `start_link`?

If your process shall only be started as a child of a supervisor, then implementing `child_spec/1` can be enough. It can directly link the `:start` parameter to another module like `GenServer`. However it's common best practice to have `start(_link)/x` functions as well, to be able to start those processes outside a supervision tree.

## Erlang libraries

Given `child_spec/1` is an elixir based convention it's something not always present for erlang libraries. For erlang libraries look out for similar functions like the one I showed for `:poolboy`. Otherwise you can either build the child spec map in a private function on the supervisor or build your own elixir module implementing `child_spec/1`, which can be used in supervisors as child, but configures `:start`, so the erlang library is started.