defmodule KobrakaiWeb.Websocket do
  use KobrakaiWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div id="websocket" phx-hook="Websocket" data-url={~p"/ws/connection_timer/blogpost"}>
      <span data-tag="init">Initializing...</span>
      <.button phx-click={JS.dispatch("request")}>Send request</.button>
      <ol class="max-h-48 overflow-x overflow-y-auto" data-tag="list"></ol>
    </div>
    """
  end

  @impl true
  def mount(_, _, socket) do
    {:ok, socket, layout: false}
  end
end
