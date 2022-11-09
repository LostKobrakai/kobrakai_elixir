defmodule KobrakaiWeb.CounterLive do
  use KobrakaiWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    Counter: <%= @counter %>
    <button type="button" phx-click="inc">+</button>
    <button type="button" phx-click="dec">-</button>
    """
  end

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, counter: 0), layout: false}
  end

  @impl true
  def handle_event("inc", _, socket) do
    {:noreply, update(socket, :counter, &(&1 + 1))}
  end

  def handle_event("dec", _, socket) do
    {:noreply, update(socket, :counter, &(&1 - 1))}
  end
end
