defmodule KobrakaiWeb.PageHTML do
  use KobrakaiWeb, :html

  embed_templates "page_html/*"

  attr :headline, :string, required: true
  attr :date, Date, required: true
  attr :url, :string, required: true
  attr :tags, :list, default: []
  attr :class, :any, default: ""
  attr :style, :string, default: ""
  attr :rest, :global

  def list_item(assigns) do
    assigns =
      update(assigns, :tags, fn tags ->
        Enum.reject(tags, &(&1 in ["blog", "project", "featured"]))
      end)

    ~H"""
    <li class={["my-2 group", @class]} style={"break-inside: avoid; #{@style}"} {@rest}>
      <.link navigate={@url}>
        <div>
          {@headline}
          <.arrow />
        </div>
        <div class="text-gray-500 dark:text-gray-400 text-sm">
          {Calendar.strftime(@date, "%d.%m.%Y")}
          <%= unless Enum.empty?(@tags) do %>
            &mdash;
            <ul class="comma-separated inline-flex">
              <li :for={tag <- @tags}>{String.capitalize(tag)}</li>
            </ul>
          <% end %>
        </div>
      </.link>
    </li>
    """
  end
end
