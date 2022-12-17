defmodule KobrakaiWeb.Scratchpad.Checkboxes do
  use KobrakaiWeb, :live_view
  use Kobrakai.Blog.ModuleCode

  on_mount {KobrakaiWeb.Hooks, :current_path}
  on_mount {KobrakaiWeb.Hooks, :noindex}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto prose dark:prose-invert">
      <.simple_form :let={f} for={@changeset} phx-change="validate" phx-submit="submit" as="form">
        <.input
          type="checkbox"
          field={{f, :items}}
          label="Options"
          options={["abc", "def", "ghi"]}
          multiple
        />

        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
      <hr />
      <.base base={@changeset.data} inspect />
      <hr />
      <.base base={@code} />
    </div>
    """
  end

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, changeset: changeset(%{items: ["abc"]}), code: module_code())}
  end

  @impl true
  def handle_event("validate", params, socket) do
    params = deal_with_html_form_encoding_shortcomings(params)

    changeset =
      socket.assigns.changeset.data
      |> changeset(params)
      |> struct!(action: :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("submit", params, socket) do
    params = deal_with_html_form_encoding_shortcomings(params)
    changeset = changeset(socket.assigns.changeset.data, params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, data} ->
        socket = put_flash(socket, :info, "Submitted successfully")
        {:noreply, assign(socket, changeset: changeset(data))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp changeset(base, params \\ %{}) do
    {base, %{items: {:array, :string}}}
    |> Ecto.Changeset.cast(params, [:items])
  end

  defp deal_with_html_form_encoding_shortcomings(params) do
    # Work around the fact that no selection submits no data
    params |> Map.get("form", %{}) |> Map.put_new("items", [])
  end

  # To be put besides phoenix 1.7 core_components before the checkbox function
  # head.
  #
  # def input(%{type: "checkbox", multiple: true} = assigns) do
  #   assigns =
  #     update(assigns, :options, fn options ->
  #       options
  #       |> Enum.map(fn
  #         # Mostly copied from Phoenix.HTML.Form.options_for_select/2
  #         {option_key, option_value} ->
  #           %{key: option_key, value: option_value, rest: %{}}

  #         option when is_list(option) ->
  #           {option_key, options} = Keyword.pop(options, :key)

  #           option_key ||
  #             raise ArgumentError,
  #                   "expected :key key when building <option> from keyword list: #{inspect(options)}"

  #           {option_value, options} = Keyword.pop(options, :value)

  #           option_value ||
  #             raise ArgumentError,
  #                   "expected :value key when building <option> from keyword list: #{inspect(options)}"

  #           %{key: option_key, value: option_value, rest: options}

  #         option ->
  #           %{key: option, value: option, rest: %{}}
  #       end)
  #       |> Enum.map(fn option ->
  #         Map.put(option, :selected, Enum.any?(assigns.value, &input_equals?(&1, option.value)))
  #       end)
  #     end)

  #   ~H"""
  #   <div phx-feedback-for={@name}>
  #     <.label for={@id}><%= @label %></.label>
  #     <div :for={option <- @options}>
  #       <input
  #         type="checkbox"
  #         id={"#{@id}_#{option.value}"}
  #         name={@name}
  #         value={option.value}
  #         checked={option.selected}
  #         class="rounded border-zinc-300 text-zinc-900 focus:ring-zinc-900 dark:border-zinc-700"
  #         {@rest}
  #       />
  #       <%= option.key %>
  #     </div>
  #     <.error :for={msg <- @errors}><%= msg %></.error>
  #   </div>
  #   """
  # end
end
