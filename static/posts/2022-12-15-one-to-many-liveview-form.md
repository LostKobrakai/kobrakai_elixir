---
title: One-to-Many LiveView Form
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
the example shown here is in memory only we'll be using an embedded schema,
but a database backed schema works just as well.

Phoenix 1.7 added support for plain maps powering forms, which seems like a 
viable alternative as well. That option won't be discussed here as part 
of updating this blog post though.

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

Using embeds also allows us to inline the `Line` embed, which is described
in more detail in the [documentation](https://hexdocs.pm/ecto/3.9.2/Ecto.Schema.html#embeds_many/3-inline-embedded-schema).

To apply changes to the defined schema and validate the input there's also the
need for `changeset/2` type functions. These should be mostly straight forward to
anyone having worked with `ecto` before, so this blog post won't go into detail 
what these functions specifically do. There's again more to read in the [documentation](https://hexdocs.pm/ecto/3.9.2/Ecto.Changeset.html).

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

## Setting up the LiveView

Getting to the meat of the topic – the LiveView itself. Starting from a mostly bare
bones implementation.

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

Usually `base` would be fetched from the database. This example again runs 
completely with data in memory, so there's just some hardcoded initial data.

`init/2` is a small helper, which generates the initial changeset behind the form,
but does also handle a few things needed just for this being in-memory. 
Changing the id also means LV will reset its client side state around 
the form properly on successful saves.

```elixir
defp init(socket, base) do
  base = autogenerate_missing_ids(base) # Mimic DB setting IDs
  changeset = GroceriesList.changeset(base, %{})

  assign(socket,
    base: base,
    form: to_form(changeset),
    id: "form-#{System.unique_integer()}" # Reset form for LV
  )
end
```

### The Form

Let's fill `render/1` with some actual markup. First the outer form with the 
`:email` input, event handler configuration and submit button, but also a 
`<fieldset>` to wrap all the nested inputs.

```heex
<.simple_form 
  :let={f}
  id={@id} 
  for={@form} 
  phx-change="validate" 
  phx-submit="submit"
  as="form">
  <.input field={f[:email]} label="Email" />

  <fieldset class="flex flex-col gap-2">
    <legend>Groceries</legend>
    <.inputs_for :let={f_line} field={f[:lines]}>
      <.line f_line={f_line} />
    </.inputs_for>
  </fieldset>

  <:actions>
    <.button>Save</.button>
  </:actions>
</.simple_form>
```

This uses `:let={f}` on the form, so the `as="form"` option is applied to inputs.
Otherwise `@form[field]` would work as well to provide the field data of the form.

The nested inputs themselves are extracted into a function component, which makes 
things a little easier to follow compared to one huge blob of html. It will also
allow us computing assigns per row later.

```heex
<div>
  <div class="flex gap-4 items-end">
    <div class="grow">
      <.input class="mt-0" field={@f_line[:item]} label="Item" />
    </div>
    <div class="grow">
      <.input class="mt-0" field={@f_line[:amount]} type="number" label="Amount" />
    </div>
  </div>
</div>
```

There used to be the need to call `Phoenix.HTML.Form.hidden_inputs_for/1` here 
when using a manual `for` comprehention with `Phoenix.HTML.Form.inputs_for/2`, 
but the newer function component `Phoenix.Component.inputs_for/1` automatically 
adds those. Those hidden inputs submit metadata like primary keys, so ecto can 
map any changes back to existing data if available.

### Getting things working

With the markup and the data backing the form out of the way we can get started 
making adding and removing lines work. 

#### Adding a line

Lets start with adding new lines to the list. For that we'll add a button within 
the `<fieldset>` wrapping the groceries list.

```heex
<fieldset class="flex flex-col gap-2">
  […]
  <.button class="mt-2" type="button" phx-click="add-line">Add</.button>
</fieldset>
```

The `phx-click` handler will send an event to the server to add a new line. How
to do that however is already a tricky topic, given how changesets work. Explaining
those requires a quick tangent:

<hr />

#### `Ecto.Changeset` in LiveView

There are two things to understand about `Ecto.Changeset`s, which make working
with it feela bit bend over backwards.

- Changesets are not stateful as in they're not mean to be continuously edited

The changeset API is a very functional one. Given a base and an input of of how
things are meant to look like at the end ecto figures out all the necessary changes
to get to that endresult. One can then validate all the changes to prevent disallowed
invariant and eventually can check if the changes are good to go or not.

The API however is not stateful in the sense that after such a round of validation
one could go back and add more changes and have the changeset know which errors
won't apply anymore. A changeset doesn't keep track of which validations were applied
end how, it only keeps their results – errors and metadata – around.

So whenever there is new input with changes to be validated the expectation is
that a new changeset is created, which again is run through the same validation
paths as the previous.

For forms in LiveView this means you don't want to store data in a changeset, 
which won't be reflected back to a new changeset by how the form on the client is 
updated. Creating a new changeset from just the form `params` should always work.

- There is no imperative API for modifying list of associations or embeds

Changesets modify associations or embeds through a set based approach. The input
to a changeset can just include how the list of associations or embeds is meant
to look like after changes are applied and ecto figures out which items need to
be added, which need to be update, which had no changes or which need to be deleted.

This is great for non-interactive clients, which have no means of modifying that
list over time by e.g. by applying "delete item a" and later applying "delete item b".
This also overlaps with the previous point of being meant to create a new 
changeset each time the set of updates to be applied changes.

Any interactivity we add to a form with LiveView will be imperative however. We
also won't have access to the forms `params` in the related event handlers. That
requires updating the existing changeset on the LiveView, but also constrains how
that can happen.

Both of those facts about changeset – which to be fair were never build to 
power interactive frontend forms – don't map too well to what LiveView allows
people to build forms.

<hr />

The mentioned properties of changesets means we'll need to be thoughful in what 
we do for handling the additional events related to our LiveView form.

```elixir
def handle_event("add-line", _, socket) do
  socket =
    update(socket, :form, fn %{source: changeset} ->
      existing = Ecto.Changeset.get_embed(changeset, :lines)
      changeset = Ecto.Changeset.put_embed(changeset, :lines, existing ++ [%{}])
      to_form(changeset)
    end)

  {:noreply, socket}
end
```

In the event handler we want to add a line to our form, but also don't want to
loose any existing changes present in the form, but not yet applied to our
`base` data. We use `get_embed` to get whatever the changeset considers the
current list of lines, including all known changes and then append a new item.
That new item doesn't have changes, so it's an empty map. The modified list is
then passed to `put_embed` to be set on the changeset.

This feels like imperative editing the changeset in place and it is. But the goal
really is that the re-rendered form on the client includes new inputs for this 
new item. So that they're visible to the user and subsequent `phx-validate` events 
include those `params` to be able to build a changeset. No other code of ours 
should need to look at that added item in the changeset again.

#### Remove a line

The second step is the inverse to the previous: removing lines. This one also 
has a few complexities:

##### Identifying the line to delete

The usual answer to identifying data especially database records would be using 
primary keys, most often the `id` of a record. The form we're looking at however 
allows adding new lines, which might only get a fixed id assigned when persisted. 
So there might be many lines without an `id` yet. Also not every database record
has a primary key.

A more flexible approach is using `@f_line.index`, which `inputs_for` sets.
That value is available and works with any schema without our code needing to
depends on any of their details, which is great.

##### Deleting existing records

HTML forms cannot send a value of "empty list". The encodings for form data
only allow for sending data on a form, but not the lack of data.

If there are two existing lines for our form, we delete the inputs for the first 
line and submit the form everything will work just fine.

If we however remove all the line inputs and submit the form the `params` would look 
like `%{email: "…"}` instead of `%{email: "…", lines: []}`. To ecto `%{email: "…"}` 
means "no changes to lines" rather than "delete existing lines". That's obviously
not what we want. 

There are few ways to work around that issue, but the cleanest is to be more more 
explicit about deletions. Instead of removing inputs for existing lines from the
form immediatelly, we instead update a flag on to be deleted lines, which makes 
them be deleted when the form is saved. 

For that to happen we need to go back and update the schema and its `changeset/2` 
function slightly to make the delete on save part work.

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

With that out of the way we can add the button to remove a line as well as the 
accompanying event handler. We'll also add a new computed assign to the `line/1` 
function component, so the few places needing the be adjusted for lines marked
to be deleted have a single assign to use.

```
assigns = assign(assigns, :deleted, Phoenix.HTML.Form.input_value(assigns.f_line, :delete) == true)
```

For educational purposes I only dropped the opacity on existing rows flagged for 
deletion, instead of hiding them completely. Feel free to adjust as needed.

```heex
<div class={if(@deleted, do: "opacity-50")}>
  […]
  <input
    type="hidden"
    name={Phoenix.HTML.Form.input_name(@f_line, :delete)}
    value={to_string(Phoenix.HTML.Form.input_value(@f_line, :delete))}
  />
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

The event handler for deleting a line is conceptionally similar to the one for
adding one. We again use the `get_embed` to fetch all current lines, split out
the one to delete and check if it's one already existing in `base` or not.

Here we check for the presense of an `id`, which is unfortunate, but for embeds
there's no good way to check if a line was part of `base` or was added to the form
later. For database backed schemas you can consider using `Ecto.get_meta(schema, :state)`.

For existing lines the event handler then marks the line as `:deleted`, while any 
other lines are fine to just be removed from the changeset immediatelly. 

```elixir
def handle_event("delete-line", %{"index" => index}, socket) do
  index = String.to_integer(index)

  socket =
    update(socket, :form, fn %{source: changeset} ->
      existing = Ecto.Changeset.get_embed(changeset, :lines)
      {to_delete, rest} = List.pop_at(existing, index)

      lines = 
        if Ecto.Changeset.change(to_delete).data.id do
          List.replace_at(existing, index, Ecto.Changeset.change(to_delete, delete: true))
        else
          rest
        end

      changeset
      |> Ecto.Changeset.put_embed(:lines, lines)
      |> to_form()
    end)

  {:noreply, socket}
end
```

### Validating and saving the form

We went to great length to consider how forms and changesets work before 
implementing adding and removing lines. For validating and saving the whole form 
this pays off, as the event handlers for `phx-change` and `phx-submit` of our form
won't look any different as they would for most other LV forms:

```elixir
def handle_event("validate", %{"form" => params}, socket) do
  changeset =
    socket.assigns.base
    |> GroceriesList.changeset(params)
    |> struct!(action: :validate)

  {:noreply, assign(socket, form: to_form(changeset))}
end

def handle_event("submit", %{"form" => params}, socket) do
  changeset = GroceriesList.changeset(socket.assigns.base, params)

  case Ecto.Changeset.apply_action(changeset, :insert) do
    {:ok, data} ->
      socket = put_flash(socket, :info, "Submitted successfully")
      {:noreply, init(socket, data)}

    {:error, changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

The `params` supplied by our form will include all the details we need to 
validate the top level inputs, but also any lines. We won't loose any not 
yet saved lines on validation and also will have any deleted lines be 
properly deleted, even if there are no more lines left on the form.

From here there could be additional features added like for example ignoring
newly added lines, which have none of their inputs filled.

If you want to play with this you can look at this example repo, which actually
stores data in the database: https://github.com/LostKobrakai/one-to-many-form

--- 

**2023-02-27**: Updated to work with phoenix 1.7.0 form changes.

**2023-01-17**: Replaced usage of `Ecto.Changeset.get_field/3` in `"add-line"` and 
`"delete-line"` event handlers with custom function using `Ecto.Changeset.get_change/3` 
with a fallback of `Ecto.Changeset.get_field/3`. This fixes a bug, where adding 
or removing a line would make changes in other lines be "forgotten".

**2023-07-26**: Replaced usage of the `Ecto.Changeset.get_change/3` and fallback
to `Ecto.Changeset.get_field/3` helper with `Ecto.Changeset.get_embed/3` as
released with ecto 3.10.