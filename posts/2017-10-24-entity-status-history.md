---
title: Entity status history using ecto
tags: 
  - blog
  - programmierung
language: EN
---
For a project of mine I recently needed to keep the history of state changes for an entity in my database. Now there are lots of resources out there about event sourcing and all those fancy event driven tools or designs. But I already have a working system and I really only needed status field changes to be persisted (at least for now).

The entity table houses the latest status value, so a simple solution to the problem would be to keep another table to track the history of old status values. My naive first approach would be to save the old status to a separate table every time it does change from its previous value. Here is an example ecto schema illustrating this approach:

```elixir
schema "entities" d
  field :status, :string
  has_many :old_statuses, OldStatuses
end
```

This would allow me to keep the history of states with metadata like “when was the status changed” or “… by whom”. What I didn’t like about this approach is the indirection between the current status and the older ones. That’s why I went for a slightly more sophisticated solution of using only the separate table to store the current as well as old statuses of an entity.

## The fancy solution

So we need to have two separate tables:

```elixir
create table(:entities) do
  add :name, :string
  timestamps()
end

create table(:entity_status) do
  add :name, :string
  add :entity_id, references(:entities)
  timestamps()
end
```

And their related ecto schemas:

```elixir
# […] entity.ex
schema "entities" do
  field :name, :string
  field :status, :string, virtual: true
  
  has_many :status_history, EntityStatus
  
  timestamps()
end

# […] entity_status.ex
schema "entity_status" do
  field :name, :string
  timestamps()
end
```

The above ecto schemas look quite similar to my initial idea, with the exception of `:status` being a virtual field. The more interesting part is saving to the database and retrieving the record again.

You are probably encapsulating your business logic via some kind of module — like a context module in phoenix — with a `create_entity/1` function and a `update_entity/2`, along with some functions for querying data from the database like `get_entity/1`. Let’s start with inserting into the database.

## Inserting entities and their current status

For this part I’ll use `Ecto.Multi` since it allows to change multiple tables of data within a single transaction with its nice API. Below is a somewhat complicated example of what you might normally do using a `changeset/2` call and `Repo.insert`:

```elixir
def create_job(attrs \\ %{}) do
  with %{valid?: true} = ch <- Entity.changeset(%Job{}, attrs),
       {:ok, %{job: job}} <- build_multi(:insert, ch) do
    {:ok, job}
  else
    %{valid?: false} = changeset ->
      apply_action(changeset, :insert)

    {:error, :entity, changeset, _} ->
      {:error, changeset}

    {:error, _, _, _} ->
      Entity.changeset(%Job{}, attrs)
      |> add_error(:status, "couldn't be created")
      |> apply_action(:insert)
  end
end
```

This part is mostly so complex because I wanted to keep the return value of `{:ok, entity} | {:error, changeset}`.

Let’s look at the actual `Ecto.Multi` part of the code. This is the part I simply reused for create as well as update tasks. That’s the reason why I did pass the `:insert` above when invoking `build_multi/2`.

```elixir
defp build_multi(action, changeset) do
  status = get_change(changeset, :status)
  
  Ecto.Multi.new()
  |> entity_multi(action, changeset)
  |> status_multi(status)
  |> Repo.transaction()
end

defp entity_multi(multi, :insert, changeset) do
  Ecto.Multi.insert(multi, :entity, changeset)
end

defp entity_multi(multi, :update, changeset) do
  Ecto.Multi.update(multi, :entity, changeset)
end

defp status_multi(multi, nil), do: multi

defp status_multi(multi, status) do
  Ecto.Multi.run(multi, :status, fn %{entity: entity} ->
    Ecto.build_assoc(entity, :status_history)
    |> EntityStatus.changeset(%{"name" => status})
    |> Repo.insert()
  end)
end
```

This will go ahead and “upsert” the entity — either insert it or update an existing one. Only if the status field did change will a new row of the `EntityStatus` struct be added into the db.

The function to update an entity is really the same as with creating one like above. Only make sure to pass the existing struct and to invoke `build_multi/2` with `:update`.

## Reading the data back from the db

Now things are stored in the database, but we still need to retrieve them again. As you might know virtual fields can’t be simply fetched from the database like any other column. So we need to make sure this does happen the way we need it to. In a freshly generated phoenix context module or also in lots of other ecto projects one does simply query for a module like so: `Repo.get(Entity, id)`. All those calls to `Entity` need to be replaced with a function call to `entity_query/0`. This will allow us to fetch the latest status in each of those instances.

```elixir
defp entity_query do
  from entity in Entity,
  join: status1 in assoc(entity, :status_history),
  left_join: status2 in EntityStatus,
    on: (entity.id == status2.job_id) and 
    (status1.updated_at < status2.updated_at or 
    (status1.updated_at == status2.updated_at and 
     status1.id < status2.id)),
  where: is_nil(status2.id),
  select: %{entity | status: status1.name}
end
```

This will join the entity with only the most recent status row and it’ll populate the `:status` virtual field with the name of the status. The field `:status_history` can still be used like any other `has_many` field.

The reason for joining the statuses table twice as `status1` and `status2` is so we are able to compare the many status associations of the entity to select only the most recent one. The `left_join` will only join `NULL` values in case its conditionals are not meet. The `where` clause skips over those rows essentially filtering out all the joined rows of older statuses.

I’ve also noticed [people suggesting subqueries](https://stackoverflow.com/a/2111420) to query for the latest status — which should work as well with ecto — but I went with the fancy solution once again. Be sure to try both if you are worried about performance.

---

So that’s it. We’ve extracted the whole status handling into a fully separate ecto schema, while still keeping the convenience of updating a textual status on the entity itself, so on the frontend one could simply use a select field for status changes.