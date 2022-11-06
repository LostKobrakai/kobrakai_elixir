---
title: A case against many_to_many
tags: 
  - blog
  - programmierung
language: EN
---

On the [Slack Channel](https://elixir-slackin.herokuapp.com/) for Elixir there's often the situation of people coming from other languages/frameworks to elixir and especially ecto to ask about "How to model many-to-many relationships". 

Most of the times the usual answer comes as a surprise to people, as usage of [`Ecto.Schema.many_to_many`](https://hexdocs.pm/ecto/3.3.4/Ecto.Schema.html#many_to_many/3) is almost actively discouraged. I'll try to bring some insights into why this is the case and what's the better alternative.

## `many_to_many` in ecto

For quite some time ecto didn't even come with `many_to_many` relationships and people instead modeled them explicitly using plain belongs_to/has_many relationships on all tables involved. But due to popular demand explicit support was eventually added. (1) 

There's one caveat though. It was added with the intent of hiding away the implementation detail of needing a join-table to create the relationship between the two many-to-many schemas. Because of that the join table can only support two foreign key columns and nothing else on the table. Those two are everything needed for modeling the relationship in the db and the only amount of information, which can be used without additional APIs for retrieving it. 

This is a serious limitation for almost all many-to-many relationships out there. I'll list a few examples:

- `User <-> Company`: This is likely to become a more featureful relationship in the future. There might be role assignments or time based access gates added.
- `Photo <-> Album`: The need to have photos in a certain order per album might come up.
- `User <-> Group`: Even just showing when a user was added to a group needs additional fields on the join table.

## Many To Many in ecto

All of the above are better modeled with an explicit schema for the join table. This way additional fields can be added to the relationship without a problem (or any new/special api to learn). For quick access and preloading purposes you can still have relationships between the outer schemas of the relationship as well.

```elixir
# Standard belongs_to/has_many
Company has_many CompanyUsers
CompanyUser belongs to Company
CompanyUser belongs to User
User has_many CompanyUsers

# But also has_many through
Company has_many Users through CompanyUsers
User has_many Companies through CompanyUsers
```
[Documentation and Actual code examples](https://hexdocs.pm/ecto/3.3.4/Ecto.Schema.html#has_many/3-has_many-has_one-through)

# Conclusion

`many_to_many` in ecto is probably not going anywhere. But now you're aware of it's limitations. Unless you really don't care about the join table and you're quite sure this won't change in the future it's better to just model the relationship explicitly and use `has_many`'s `through` option to get all the convenience of loading relationships via the join schema if that's all you need.

1: http://pages.plataformatec.com.br/ebook-whats-new-in-ecto-2-0