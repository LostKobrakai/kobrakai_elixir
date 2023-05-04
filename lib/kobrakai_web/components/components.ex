defmodule KobrakaiWeb.Components do
  use Phoenix.Component
  use KobrakaiWeb, :verified_routes

  attr :back, :boolean

  def brand_header(assigns) do
    ~H"""
    <header class="flex h-64 my-4 justify-center items-center 2xl:absolute 2xl:w-64 2xl:-translate-x-full transition duration-150">
      <div class="w-20 h-20">
        <%= if @back do %>
          <.link class="group" navigate={~p"/"}>
            <img
              class="block group-hover:hidden dark:invert"
              src={~p"/images/signee.png"}
              alt="Benjamin Milde"
            />
            <.back_button class="hidden group-hover:block dark:invert" />
          </.link>
        <% else %>
          <img class="dark:invert" src={~p"/images/signee.png"} alt="Benjamin Milde" />
        <% end %>
      </div>
    </header>
    """
  end

  attr :rest, :global

  def back_button(assigns) do
    ~H"""
    <img src={~p"/images/pfeil.png"} alt="Back" {@rest} />
    """
  end

  attr :list, :list, required: true
  attr :max, :integer, required: true
  attr :reverse, :boolean, default: false
  slot :inner_block, required: true
  slot :link

  def limited_listing(%{list: list, reverse: reverse, max: max} = assigns) do
    rendered =
      if(reverse, do: Enum.reverse(list), else: list)
      |> Enum.take(max)

    assigns =
      assigns
      |> assign(:rendered, rendered)
      |> assign(:length, length(list))

    ~H"""
    <%= render_slot(@inner_block, @rendered) %>
    <%= if @length > abs(@max) && @link != [] do %>
      <%= render_slot(@link, @length) %>
    <% end %>
    """
  end

  attr :direction, :string, values: ["left", "top-left"], default: "left"

  def arrow(assigns) do
    ~H"""
    <span
      class={[
        "inline-block transition duration-100 group-hover:translate-x-1",
        if(@direction == "left", do: "group-hover:translate-x-1"),
        if(@direction == "top-left",
          do: "rotate-45 group-hover:translate-x-1 group-hover:-translate-y-1"
        )
      ]}
      aria-hidden="true"
    >
      <%= case @direction do %>
        <% "left" -> %>
          &rarr;
        <% "top-left" -> %>
          &uarr;
      <% end %>
    </span>
    """
  end

  attr :base, :any, required: true
  attr :inspect, :boolean, default: false

  def base(assigns) do
    code =
      if assigns.inspect do
        inspect(assigns.base, pretty: true)
      else
        assigns.base
      end

    assigns = assign(assigns, :formatted, Makeup.highlight_inner_html(code))

    ~H"""
    <pre class="makeup elixir"><%= Phoenix.HTML.raw(@formatted) %></pre>
    """
  end
end
