---
title: "Ecto: When to cast"
tags: 
  - blog
  - programmierung
language: EN
---
People starting out with ecto are often confused by all the methods of getting changes applied to a changeset and therefore the database. Especially the options around assocications are often problematic. To bring some clarity into the matter one first needs to understand a thing about the architecture ecto and changesets operate under.

There are three conceptional types of data ecto deals with. There's user input, which is often provided in a subset of data types of what a schema is meant to carry. E.g. in a web context forms often submit data with text values only. JSON serialize data might know a few more data types, but is still quite limited. Then there's the actual values one want's to have have at runtime in schemas – your `field :some_name, :date` being a `%Date{}`. The third type is the data type the runtime data is serialized into for database storage. 

Converting user input into the runtime data type is called "casting". `Ecto.Changeset` exposes 3 functions for doing that when applying changes: `cast/4`, `cast_assoc/3` and `cast_embed/3`.

Changes are not always "user input", which needs casting. E.g. in an event sourcing system one might handle events, whose data has been validated before and is no longer expressed by constrainted data types. Those can be applied by another set of functions on `Ecto.Changeset`: `change/2`, `put_change/3`, `put_assoc/4` and `put_embed/4`. For those functions values for fields are expected to already be "runtime format" values,
which don't need to be casted.

Therefore which set of function to go for is determined by what data you want to apply as change. For changing fields on a schema you'd use `cast/4`, `change/2` or `put_change/3`. For changing values on an associations `cast_assoc/3` or `put_assoc/4`, while for embeds it's `cast_embed/3` or `put_embed/4`. 

## Creating relationships

Both `cast_assoc/3` and `put_assoc/4` compare preloaded assocs with the input provided. The existing data is then morphed to match the input by creating/updating/deleteing elements. This does not create "just an relationship" to an already existing record in the db. It's therefore only really useful if the whole set of assocs is handled (handling just subsets is possible but uncommon). 

The same is true for embeds, but as partial updates are not really a things on embeds at the db level as well it's usually fine.

Therefore for creating relationships for existing records or updating a parent and maybe a single somehow special assoc it's usually simpler to opt for other solution like manually updating those separately. Likely using `Ecto.Multi`.