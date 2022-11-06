---
title: Ecto abstract tables
headline: Phoenix contexts and ecto abstract tables
tags: 
  - blog
  - programmierung
language: EN
---
Phoenix 1.3 introduced the concept of [contexts](http://hexdocs.pm/phoenix/contexts.html) in a application. Even though it’s a simple idea on paper — structure you application in modules and functions, which belong to a related context—it’s been an eye-opener for my own projects. I think much more about how high or low level some part of my application is and where the dependencies are between those parts.

One recent result of this awareness was the addition of address handling and retail-stores into an application. Stores are a key element of that application, so they’re a rather high level element. Addresses on the other hand are just a bunch of strings and location data—as well as not really limited in usage for stores—therefore they’re rather low level.

I quickly added the two contexts `retailers` and `addresses` to my application as well as schemas for `Store` and `Address`. But when it got to adding the association between both I got kinda stuck. The `Address` shouldn’t need to know about a more high level concept of stores yet a association of `has_one :address, Address` on the `Store` schema would mean putting a `store_id` column in the `addresses` table. At the same time `belongs_to :address, Address` is incorrect as well.

This is where ectos [abstract tables](https://hexdocs.pm/ecto/2.2.6/Ecto.Schema.html#belongs_to/3-polymorphic-associations) feature comes into play. It’s a way to define a low level abstract schema `Address` which is not linked to any specific table. It’s simply a blueprint, which each higher level component like my `Store` schema can use in combination with its own addresses table like this: `has_one :address, {"store_addresses", Address}, foreign_key: :assoc_id`. So this new table can have it’s `assoc_id` linking to the `stores` table without interfering with any other addresses I might need to store for that application. The documentation about the feature also mentions this as being more performant and overall a better design for the database. At runtime everything stays as it was. Each `Address` struct will still be the same—besides the primary key.

So being aware of those dependencies between contexts and they’re place within the application actually lead me to a better database architecture and told me that I’m working with the concept of polymorphic associations even before I had the actual use-case of sharing the address schema with multiple higher level elements.

So the TLDR would be: If neither `belongs_to` nor `has_one/has_many` seem to fit your use case maybe take a look at abstract tables.