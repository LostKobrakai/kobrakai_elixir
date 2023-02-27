defmodule KobrakaiWeb.Scratchpad.Checkboxes do
  use KobrakaiWeb, :live_view
  use Kobrakai.Blog.ModuleCode

  on_mount {KobrakaiWeb.Hooks, :scratchpad}
  on_mount {KobrakaiWeb.Hooks, :current_path}
  on_mount {KobrakaiWeb.Hooks, :noindex}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto prose dark:prose-invert">
      <.simple_form :let={f} for={@form} phx-change="validate" as="form">
        <.input
          type="checkbox"
          field={f[:items]}
          label="Options"
          options={["abc", "def", "ghi"]}
          multiple
        />
      </.simple_form>
      <hr />
      <.base base={@form.params} inspect />
      <hr />
      <.base base={@code} />
    </div>
    """
  end

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, form: to_form(%{"items" => ["abc"]}), code: module_code())}
  end

  @impl true
  def handle_event("validate", params, socket) do
    form_params = deal_with_html_form_encoding_shortcomings(params)
    {:noreply, assign(socket, form: to_form(form_params))}
  end

  defp deal_with_html_form_encoding_shortcomings(params) do
    # Work around the fact that no selection submits no data
    params |> Map.get("form", %{}) |> Map.put_new("items", [])
  end

  # To be put besides phoenix 1.7 core_components before the checkbox function
  # head.
  #
  # def input(%{type: "checkbox", multiple: true} = assigns) do
  #   escaped_values = Enum.map(assigns.value, &Phoenix.HTML.html_escape/1)
  #
  #   assigns =
  #     update(assigns, :options, fn options ->
  #       options
  #       |> Enum.map(fn
  #         {option_key, option_value} ->
  #           %{key: option_key, value: option_value, rest: %{}}
  #
  #         option when is_list(option) ->
  #           {option_key, options} = Keyword.pop(options, :key)
  #
  #           option_key ||
  #             raise ArgumentError,
  #                   "expected :key key when building <option> from keyword list: #{inspect(options)}"
  #
  #           {option_value, options} = Keyword.pop(options, :value)
  #
  #           option_value ||
  #             raise ArgumentError,
  #                   "expected :value key when building <option> from keyword list: #{inspect(options)}"
  #
  #           %{key: option_key, value: option_value, rest: options}
  #
  #         option ->
  #           %{key: option, value: option, rest: %{}}
  #       end)
  #       |> Enum.map(fn option ->
  #         escaped_value = Phoenix.HTML.html_escape(option.value)
  #         Map.put(option, :checked, escaped_value in escaped_values)
  #       end)
  #     end)
  #
  #   ~H"""
  #   <div phx-feedback-for={@name}>
  #     <.label for={@id}><%= @label %></.label>
  #     <div :for={option <- @options}>
  #       <input
  #         type="checkbox"
  #         id={"#{@id}_#{option.value}"}
  #         name={@name}
  #         value={option.value}
  #         checked={option.checked}
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
