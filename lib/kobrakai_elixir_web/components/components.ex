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
            <img class="hidden group-hover:block dark:invert" src={~p"/images/pfeil.png"} alt="Back" />
          </.link>
        <% else %>
          <img class="dark:invert" src={~p"/images/signee.png"} alt="Benjamin Milde" />
        <% end %>
      </div>
    </header>
    """
  end
end
