---
title: One-to-Many LiveView Form
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

There are however a few foot-guns when approaching forms like that. Some due
to how html forms work, but also some due to the historical use of `Ecto.Changeset` 
to power forms. Changesets are great, but especially combined with LiveView they
can feel limiting.

So let's consider the following form for creating a groceries list to send to 
someone via email – sending part non functional. This involves a root level input
for the email address and zero or more rows of multiple inputs for defining the 
list.

## Interactive Example

<!-- [KobrakaiWeb.OneToManyForm] -->

<hr>

## The schema

To start from the beginning – we'll need a schema to power our form. There
are schemaless changesets, but the `Phoenix.HTML.Form` implementation for
changesets doesn't support nested forms using schemaless changesets. Given 
the example shown here is in memory only I'll be using an embedded schema,
but a database backed schema works just as well.

```elixir
defmodule GroceriesList do
  use Ecto.Schema

  embedded_schema do
    field(:email, :string)

    embeds_many :lines, Line, on_replace: :delete do
      field(:item, :string)
      field(:amount, :integer)
    end
  end
end
```

Using embeds also allows me to inline the `Line` embed, which is described
in more detail in the [documentation](https://hexdocs.pm/ecto/3.9.2/Ecto.Schema.html#embeds_many/3-inline-embedded-schema).

To apply changes to the defined schema and validate the input there's also the
need for `changeset/2` type functions. These should be mostly straight forward to
anyone having worked with `ecto` before, so I won't go into detail what these 
functions specifically do.

```elixir
defmodule GroceriesList do
  […]
  import Ecto.Changeset

  def changeset(form, params) do
    form
    |> cast(params, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> cast_embed(:lines, with: &line_changeset/2)
  end

  def line_changeset(city, params) do
    city
    |> cast(params, [:item, :amount])
    |> validate_required([:item, :amount])
  end
end
```

## The LiveView

Getting to the meat the next will be implementing the form – starting with a bare
bones LiveView.

```elixir
defmodule GroceriesWeb.ListLive do
  use GroceriesWeb, :live_view

  @impl true
  def render(assigns) do
    […]
  end

  @impl true
  def mount(_, _, socket) do
    base = %GroceriesList{
      id: "4e4d0944-60b3-4a09-a075-008a94ce9b9e",
      email: "friend@example.com",
      lines: [
        %GroceriesList.Line{
          id: "26d59961-3b19-4602-b40c-77a0703cedb5",
          item: "Melon",
          amount: 1
        },
        %GroceriesList.Line{
          id: "330a8f72-3fb1-4352-acf2-d871803cd152",
          item: "Grapes",
          amount: 3
        }
      ]}

    {:ok, init(socket, base)}
  end
end
```

In most applications `base` would likely be fetched from the database. This example
runs completely with data in memory, so there's just some hardcoded initial data.

`init/2` is a small helper, which generates the initial changeset for the form,
but also does handle a few things – again – needed just for this being in-memory 
instead of being backed by a database. Changing the id also means LV will reset
its client side state around the form properly on successful saves.

```elixir
defp init(socket, base) do
  base = autogenerate_missing_ids(base) # Mimic DB setting IDs
  changeset = GroceriesList.changeset(base, %{})

  assign(socket,
    base: base,
    changeset: changeset,
    id: "form-#{System.unique_integer()}" # Reset form for LV
  )
end
```

### The Form

Let's fill `render/1` with some actual markup. First the outer form with the `:email` input, event handlers and submit button, but also a `<fieldset>` to wrap all the nested inputs.

```heex
<.simple_form 
  :let={f} 
  id={@id} 
  for={@changeset} 
  phx-change="validate" 
  phx-submit="submit"
  as="form">
  <.input field={{f, :email}} label="Email" />

  <fieldset class="flex flex-col gap-2">
    <legend>Groceries</legend>
    <%= for f_line <- Phoenix.HTML.Form.inputs_for(f, :lines) do %>
      <.line f_line={f_line} />
    <% end %>
  </fieldset>

  <:actions>
    <.button>Save</.button>
  </:actions>
</.simple_form>
```

The nested inputs themselves are extracted into a function component, which makes things a little easier to follow.

```heex
<div>
  <%= Phoenix.HTML.Form.hidden_inputs_for(@f_line) %>
  <div class="flex gap-4 items-end">
    <div class="grow">
      <.input class="mt-0" field={{@f_line, :item}} label="Item" />
    </div>
    <div class="grow">
      <.input class="mt-0" field={{@f_line, :amount}} type="number" label="Amount" />
    </div>
  </div>
</div>
```

### Getting things working

#### Adding a line

With the markup and the data backing the form out of the way we can get started 
making this actually work. Lets start with adding new lines to the list. For that
we'll add a button within the `<fieldset>` wrapping the groceries list.

```heex
<fieldset class="flex flex-col gap-2">
  […]
  <.button class="mt-2" type="button" phx-click="add-line">Add</.button>
</fieldset>
```

The `phx-click` handler will send an event to the server to add a new line. How
to do that however is already a tricky topic, given how changesets work. 

<hr />

#### `Ecto.Changeset` in LiveView

There are two things to understand about `Ecto.Changeset`s, which feel a bit
strange in the context of LiveView. 

- Changesets are not stateful as in they're not mean to be continuously edited

The changeset API is a very functional one. Given a starting value and input,
which maps to an "envisioned" endresult the data should be morphed to it figures
out the changes, validates that changes don't conflict with constraints and 
eventually applies changes. 

It doesn't do any stateful stuff though. It doesn't track validations applied
to a changeset – it keeps only metadata – so validations cannot be reapplied. 
It does never remove errors for a given field, even if it is changed again.

For forms this means you don't want to store data in a changeset, which won't
be reflected back to a new changeset by how the form on the client is updated. 
Creating a new changeset from just the form `params` should always work.

- Associations and embeds are dealt with in sets

Changesets modify associations or embeds not through actions like
`add` or `remove`, but through a set based approach. Instead of e.g. deleting 
the last item it'll figure out to delete it when the supplied list doesn't contain
that item anymore. By comparing the existing list with the supplied one ecto can
figure out which items need to be added, edited, kept as is or deleted.

Both of those facts about changeset – which to be fair were never build to 
power dynamic frontend forms – don't match to well with LiveView forms 
becoming more event driven and less driven by a single set of submitted input
values.

<hr />

The mentioned properties of changesets means we'll need to adjust what we do
for handling the events of our LiveView.

```elixir
def handle_event("add-line", _, socket) do
  socket =
    update(socket, :changeset, fn changeset ->
      existing = Ecto.Changeset.get_field(changeset, :lines, [])
      Ecto.Changeset.put_embed(changeset, :lines, existing ++ [%{}])
    end)

  {:noreply, socket}
end
```

In the event handler we want to add a line to our form. We use `put_embed` to
change the list of `:lines`. To do that we pass a list with all existing lines
and include an additional line, which is supposed to be without any changes yet, 
therefore the empty list. 

Updating the changeset makes the form render one more entry for `inputs_for/2`,
so and subsequent parameters from the form sent to the server will also include
this new line.

#### Remove a line

The other step to deal with is the opposite of adding lines: removing lines. 
This one has a few complexities:

##### Identifying the line to delete

The usual answer to identifying especially database records would be using their
primary key, most often the `id`. The form we're looking at however allows adding
new lines, which might only get a fixed id assigned when persisted, so there
might be many lines without an `id`. 

A more flexible approach is using `@f_line.index`, which `inputs_for` supplies.
That value doesn't need to know anything about the schema used with `inputs_for`,
which is really useful.

##### Deleting existing records

HTML forms cannot send a value of "empty list". The encodings for form data
only allow for sending data on a form, but not the lack of data.

If we would just update our changeset to no longer include any removed lines
that would update the form on the client to include no inputs, so submitted
`params` would look like `%{email: "…"}` instead of `%{email: "…", lines: []}`.

To ecto `%{email: "…"}` means "no changes to lines" rather than "delete existing lines".

This can be avoided by being more explicit. Instead of removing lines, which are
persisted, we update them with a flag, which makes them be deleted when the form
is saved. For that we need to update the schema and its `changeset/2` function.

```elixir
embeds_many :lines, Line, on_replace: :delete do
  […]
  field(:delete, :boolean, virtual: true)
end

[…]

def line_changeset(city, params) do
  changeset =
    city
    |> cast(params, [:item, :amount, :delete])
    |> validate_required([:item, :amount])

  if get_change(changeset, :delete) do
    %{changeset | action: :delete}
  else
    changeset
  end
end
```

With that information we can add the button to remove a line as well as the 
accompanying event handler.

Adding this in the `line/1` function component:

```
assigns = assign(assigns, :deleted, Phoenix.HTML.Form.input_value(assigns.f_line, :delete) == true)
```

And updating its template. For educational purposes I dropped the opacity on
persisted rows flagged for deletion, instead of hiding them completely.

```heex
<div class={if(@deleted, do: "opacity-50")}>
  […]
  <.input field={{@f_line, :delete}} type="hidden" />
  <div class="flex gap-4 items-end">
    […]
    <.button
      class="grow-0"
      type="button"
      phx-click="delete-line"
      phx-value-index={@f_line.index}
      disabled={@deleted}
    >
      Delete
    </.button>
  </div>
</div>
```

The event handler flags existing lines as `:deleted`, while not yet persisted
lines are fine to just be removed from the changeset. 

```elixir
def handle_event("delete-line", %{"index" => index}, socket) do
  index = String.to_integer(index)

  socket =
    update(socket, :changeset, fn changeset ->
      existing = Ecto.Changeset.get_field(changeset, :lines, [])
      {to_delete, rest} = List.pop_at(existing, index)

      if Ecto.Changeset.change(to_delete).data.id do
        updated =
          List.replace_at(existing, index, Ecto.Changeset.change(to_delete, delete: true))

        Ecto.Changeset.put_embed(changeset, :lines, updated)
      else
        Ecto.Changeset.put_embed(changeset, :lines, rest)
      end
    end)

  {:noreply, socket}
end
```

### Validating and saving the form

For adding and removing lines we went to great length to consider how forms and 
changesets work before implementing anything. For validating and saving this 
pays off, as the event handlers for `phx-change` and `phx-submit` of our form
won't look any different as they would for most other LV forms:

```elixir
def handle_event("validate", %{"form" => params}, socket) do
  changeset =
    socket.assigns.base
    |> GroceriesList.changeset(params)
    |> struct!(action: :validate)

  {:noreply, assign(socket, changeset: changeset)}
end

def handle_event("submit", %{"form" => params}, socket) do
  changeset = GroceriesList.changeset(socket.assigns.base, params)

  case Ecto.Changeset.apply_action(changeset, :insert) do
    {:ok, data} ->
      socket = put_flash(socket, :info, "Submitted successfully")
      {:noreply, init(socket, data)}

    {:error, changeset} ->
      {:noreply, assign(socket, changeset: changeset)}
  end
end
```

The `params` supplied by our form will include all the details we need to 
validate the top level inputs, but also any lines. We won't loose any not 
yet persisted lines on validation and also will have any deleted lines be 
properly deleted, even if this means there are no more lines on the data.

From here there could be additional features added like for example ignoring
newly added lines, which have non of their inputs filled.

If you want to play with this you can look at this example repo, which actually
stores data in the database: https://github.com/LostKobrakai/one-to-many-form