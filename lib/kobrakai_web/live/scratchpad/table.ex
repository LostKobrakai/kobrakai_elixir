defmodule KobrakaiWeb.Scratchpad.Table do
  use KobrakaiWeb, :live_view
  use Kobrakai.Blog.ModuleCode

  on_mount {KobrakaiWeb.Hooks, :scratchpad}
  on_mount {KobrakaiWeb.Hooks, :current_path}
  on_mount {KobrakaiWeb.Hooks, :noindex}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto prose dark:prose-invert">
      <div class="p-8">
        <.adjusted_table id="users" rows={@rows}>
          <:col :let={user} label="id"><%= user.id %></:col>
          <:col :let={user} label="username"><%= user.username %><br />Multiline</:col>
          <:action>Action 1</:action>
          <:action>Action 2</:action>
        </.adjusted_table>
      </div>
      <div class="p-8">
        <.adjusted_table id="users" rows={@rows}>
          <:col :let={user} label="id"><%= user.id %></:col>
        </.adjusted_table>
      </div>
      <hr />
      <.base base={@code} />
    </div>
    """
  end

  @impl true
  def mount(_, _, socket) do
    rows = [
      %{id: 1, username: "John"},
      %{id: 2, username: "Jane"}
    ]

    {:ok, assign(socket, rows: rows, code: module_code())}
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :row_click, :any, default: nil
  attr :rows, :list, required: true

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def adjusted_table(assigns) do
    ~H"""
    <div id={@id} class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="mt-11 w-[40rem] sm:w-full">
        <thead class="text-left text-[0.8125rem] leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">
              <%= col[:label] %>
            </th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only"><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
          <tr
            :for={{row, index} <- Enum.with_index(@rows)}
            id={"#{@id}-#{index}"}
            class="group hover:bg-zinc-50"
          >
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={[
                "p-0 relative",
                rounded_start(),
                @action == [] && rounded_end(),
                @row_click && "hover:cursor-pointer"
              ]}
            >
              <div class="block py-4 pr-6">
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, row) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class={["p-0 w-14 relative", rounded_end()]}>
              <div class="whitespace-nowrap py-4 text-right text-sm font-medium">
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, row) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp rounded_start do
    "first:before:absolute first:before:h-full first:before:w-4 first:before:top-0 first:before:-left-4 first:before:group-hover:bg-zinc-50 first:before:sm:rounded-l-xl"
  end

  defp rounded_end do
    "last:after:absolute last:after:h-full last:after:w-4 last:after:top-0 last:after:-right-4 last:after:group-hover:bg-zinc-50 last:after:sm:rounded-r-xl"
  end
end
