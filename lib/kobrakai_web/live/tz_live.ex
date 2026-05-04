defmodule KobrakaiWeb.TzLive do
  use KobrakaiWeb, :live_view

  on_mount {KobrakaiWeb.Hooks, :current_path}
  on_mount {KobrakaiWeb.Hooks, :current_user}
  on_mount {KobrakaiWeb.Hooks, :localize}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto prose dark:prose-invert">
      <p>I'm currently in <code>{@tz}</code> timezone.</p>
      <p>It's <time>{Localize.Time.to_string!(@now, format: :short)}</time> here.</p>
      <p>Last updated on <time>{Localize.Date.to_string!(@last_updated, format: :medium)}</time></p>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    tz = "Europe/Berlin"
    now = DateTime.now!(tz) |> DateTime.truncate(:second)
    last_updated = ~D[2026-05-04]
    {:ok, assign(socket, tz: tz, now: now, last_updated: last_updated)}
  end
end
