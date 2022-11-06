---
title: "Unnest for runtime sorted results"
tags: 
  - blog
  - programmierung
language: EN
excerpt: |
  How to get a dynamic list of items into an ecto query without storing it in the database.
---

The recent `ecto` 3.5 update introduced the parameterized type `Ecto.Enum`, which
is a great way to use atoms in elixir for signifying things like statuses or 
types of data. In the database those values are stored as plain strings, so 
they're easy to manage there as well – until it comes to sorting by those columns.

The simplest solution for sorting not alphabetically, but by e.g. the order the
statuses are applied, is likely to use an proper `enum` column in the database or
joining a table in the db, which holds an index for each possible value in a secondary
column.

## Arbitrary order

But what about arbitrary sorting, which cannot be placed in the db?

For postgres there's the possibility to build that join table dynamically with
`unnest` instead of an actual table. The usual answer one finds on the internet 
most often involves using `VALUES` lists, but they don't really work well with 
ecto queries, as they're not easily parameterized. `unnest` luckily can be:

```elixir 
defmodule MyApp.QueryHelpers
  @doc """
  Unnest into an table format.

  ## Example

      import MyApp.QueryHelpers

      status = [:waiting, :running, :done]
      order = [1, 2, 3]

      from jobs in "jobs", 
        join: ordering in unnest(^status, ^order), 
        on: jobs.status == ordering.a,
        order_by: ordering.b

  """
  defmacro unnest(list_a, list_b) do
    quote do
      fragment("SELECT * FROM unnest(?, ?) AS t(a, b)", unquote(list_a), unquote(list_b))
    end
  end
end
```

As you can see `unnest` does work with plain lists, which can be passed as 
parameters and therefore work with `fragment`. This allows to build up an table
of arbitrary size (more columns could be done by adding additional arities for 
the `unnest` helper), which can be joined to the data in the database.

## Updating pagination

Given we're manually supplying the list of "positions" this can not only be used
for read operations, but e.g. also for updates for things like position columns
for data ordered in the db.

```elixir
@spec update_order(%{produce_id :: integer => new_position :: integer}) :: result :: term
def update_order(new_order) do
  {ids, positions} = Enum.unzip(new_order)

  query =
      from p in Product,
        join:
          positions in unnest(
            type(^ids, {:array, :integer}),
            type(^positions, {:array, :integer})
          ),
        on: p.id == positions.a,
        update: [set: [position: positions.b]]

    Repo.transaction(fn ->
      # Create deferable constraint like that (not `unique_index/3`):
      # 
      # execute("""
      # ALTER TABLE products
      # ADD constraint products_position_unique unique (position) deferrable;
      # """, "")
      # 
      # This allows for all rows to update before checking if everything is
      # still unique.
      Repo.query!("SET CONSTRAINTS products_position_unique DEFERRED")
      Repo.update_all(query, [])
    end)
end
```