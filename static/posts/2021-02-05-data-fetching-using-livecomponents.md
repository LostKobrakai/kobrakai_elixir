---
title: "Data fetching using LiveComponents"
tags: 
  - blog
  - programmierung
language: EN
excerpt: |
  Learn about the power behind the preload callback in liveview components
---

A common occurance in my phoenix applications is the need to render a list of 
some items – say companies in a job board application. Let's start out simple 
by using the phoenix generators to build up the first bunch of boilerplate for
those companies:

```bash
$ mix phx.gen.live JobBoard Company companies name:string website:string
```

This does generate a liveview module `MyAppWeb.CompanyLive.Index`, which for the
liveaction `:index` can render a nice list of companies.

But usually things do not stop here. Let's say the next requirement is adding
the number of jobs published per company in that table on the index page. A quick
look into the liveview module will reveal that it calls into its related context 
module to fetch companies' data for rendering.

```elixir
def list_companies() do
  Repo.all(Company)
end
```

## Preloading

Assuming jobs are related to companies in the database using foreign keys one obvious 
way of handling the requirement would be to preload jobs from the database and count 
them up in the template:

```elixir
def list_companies() do
  Company 
  |> Repo.all() 
  |> Repo.preload(:jobs)
end

# In the template
<td><%= Enum.count(company.jobs) %></td>
```

This however has the downside of loading much more data from the database than 
required. So another approach could be loading the number of jobs directly from
the database instead of counting jobs within elixir.
## Subquery

```elixir
def list_companies() do
  jobs_by_company = 
    from j in Jobs, 
      group_by: j.company_id, 
      select: %{
        company_id: j.company_id, 
        job_count: count(j.id)
      }

  companies_query = 
    from c in Company, 
      join: jc in subquery(jobs_by_company), 
      on: c.id == jc.company_id, 
      select: %{c | job_count: jc.job_count}

  Repo.all(companies_query) 
end

# In the company schema
field :job_count, :integer, virtual: true

# In the template
<td><%= company.job_count %></td>
```

This works great. The database sums up the number of jobs per company and it's 
simply stored in a virtual field on the company schema. No longer are whole jobs
loaded just to count them up.

## Multiple collections

Let's imagine another requirement. The JobBoard in the meantime got a new feature:
people can submit rating for companies, any company not just the ones publishing
jobs. Still the companies index shall show the average rating of each company.
That rating itself is part of a completely different context and there's no foreign
key relationship on the database level. Querying that separate context from within
the JobBoard context doesn't feel like a great solution. Those companies are only
related to ratings on the UI level. 

Given the last approach is no longer a great one the data loading needs to become
multiple steps:

```elixir
companies = JobBoard.list_companies()
ratings = Comparator.list_ratings(companies)
```

This seems simple, but is a bit convoluted on the template level:

```html_eex
<%= for company <- @companies do %>
  <% rating = Map.get(@ratings, company.id) %>
  …
<% end %>
```

One would love to just be able to do `company.rating` instead, but there is no 
`:rating` field on the company schema. Searching the ratings for the
current company in the iteration each time doesn't seem nice.

## LiveComponent

The approach I recently adopted is using live components to compose the various
places to fetch data from. Instead of taking all companies, loading all the related
ratings in one place, just to bring together individual companies with their 
individual rating in a completely other place – live components allow for all
that to happen in one place.

```html_eex
<%= for company <- @companies do %>
  <% live_component @socket, Row, id: company.id, company: company %>
<% end %>
```

```elixir
defmodule MyAppWeb.CompanyLive.IndexRowComponent do
  use MyAppWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <tr>
      <td><%= @company.name %></td>
      <td><%= @rating %></td>
    </tr>
    """
  end

  @impl true
  def preload(list_of_assigns) do
    companies = Enum.map(list_of_assigns, & &1.company)
    ratings = Comparator.list_ratings(companies)

    Enum.map(list_of_assigns, fn assigns ->
      Map.put(assigns, :rating, Map.get(ratings, assigns.company))
    end)
  end
end
```

The [`preload/1`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html#module-preloading-and-update) callback for those components allows for data fetching to happen
on the whole set of companies – preventing N+1 query issues – while the template
simply works on per company data, which does hold a simple `@rating`. No need to
deal with mapping individual ratings back to companies in the template itself.

Besides making templates cleaner I also like the idea of letting the liveview 
itself only deal with fetching companies, which is it's job. While metadata is
only added if actually needed. Imagine the rating column is not always enabled.
If the component loading ratings is not rendered nothing is loaded. It allows in
my opinion for a much better locality as there's not just one "controller" 
(the liveview) and one view layer (the template), but it's layers of components, 
which load just the data they themselves need. 

Having the `preload/1` callback the danger of n+1 queries within loops is 
mitigated. The only downside left however is multiple different components fetching 
the same data on demand. Here `n` would be the number of components though instead
of the number of loop iterations. 