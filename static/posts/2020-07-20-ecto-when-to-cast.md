---
title: "Ecto: When to cast"
tags: 
  - blog
  - programmierung
language: EN
---
People starting out with ecto are often confused by all the methods of getting changes applied to a changeset and therefore the database. Especially the options around assocications are often problematic. To bring some clarity into the matter one first needs to understand a thing about the architecture ecto and changesets operate under.

## Looking at `Ecto.Type`

There are three conceptional types of data ecto deals with. There's user input, which is often provided in a subset of data types of what a schema is meant to carry. E.g. in a web context forms often submit data with text values only. JSON serialize data might know a few more data types, but is still quite limited. Then there's the actual values one want's to have have at runtime in schemas – your `field :some_name, :date` being a `%Date{}`. The third type is the data type the runtime data is serialized into for database storage. 

The following shows a concrete example of those three types of representations for the underlying value.

```elixir
# Plain string, describing a date in iso8601, 
# but needs to be parsed to be sure.
input_date = "2020-07-20"

# Using proper elixir type of a %Date{} struct, 
# which one can be sure about being a proper date.
runtime_date = ~D[2020-07-20]

# This is the same as the runtime_date, as ecto's database 
# drivers are expected to be able to handle that directly.
# That usually isn't the case however for custom ecto types.
database_date = ~D[2020-07-20]
```

Conversion between those types of values is provided by `Ecto.Type` – natively or using custom implementation of its behaviour.

```elixir
# input -> runtime
runtime_date = Ecto.Type.cast(:date, input_type)

# database -> runtime
runtime_date = Ecto.Type.load(:date, database_date)

# runtime -> database
database_date = Ecto.Type.dump(:date, runtime_date)
```

There's no way of going from the runtime value to a possible input value, but that's not needed, at least
in the context of ecto.

## Applying that to `Ecto.Changeset`

As shown before turning user input into the runtime data type is using `Ecto.Type.cast/2` and is therefore called "casting". `Ecto.Changeset` exposes 3 functions for doing to a whole set of values being the user input: `cast/4`, `cast_assoc/3` and `cast_embed/3`.

However changes applied on a changeset are not always "user input" and therefore don't always need to involve "casting" the changes. E.g. in an event sourcing system one might handle events, whose data has been validated before and is no longer expressed by constrainted data types. Those can be applied by another set of functions on `Ecto.Changeset`: `change/2`, `put_change/3`, `put_assoc/4` and `put_embed/4`. For those functions values for fields are expected to already be "runtime format" values,
which don't need to be casted.

| |Needs Casting|No Casting|
|-|-|-|
|Schema Values|`cast/4`|`change/2`/`put_change/3`|
|Assoc Values|`cast_assoc/3`|`put_assoc/4`|
|Embed Values|`cast_embed/3`|`put_embed/4`|

## Creating relationships

Both `cast_assoc/3` and `put_assoc/4` as well as their embedded counterparts compare preloaded data with the input provided. 

From there a set based comparison is done. All new items in the input are created. All existing items are updated if needed. All no longer available items are deleted. Items not present in both previous data or input are ignored – that's only really possible for assocs though. Matching of items is done based in primary key.

All those APIs are not suitable for creating "just an relationship" of already existing records in the db. For creating relationships for existing records or updating a parent and maybe a single somehow special assoc it's usually simpler to opt for other solution like manually updating those separately. Likely using `Ecto.Multi`.