defmodule KobrakaiWeb.ConnectionTimer do
  use KobrakaiWeb, :verified_routes
  @behaviour WebSock

  @impl true
  def init(%{path_params: %{"name" => name}}) do
    path = ~p"/ws/connection_timer/#{name}"
    schedule_alert()
    {:ok, %{start: now(), path: path}}
  end

  @impl true
  def handle_in({"request_timer", opcode: :text}, state) do
    {:push, {:text, "Connected to #{state.path} for #{diff(state.start)}s."}, state}
  end

  def handle_in(_, state) do
    {:ok, state}
  end

  @impl true
  def handle_info(:alert, state) do
    schedule_alert()
    {:push, {:text, "Alert for #{state.path} after #{diff(state.start)}s."}, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  defp now, do: System.monotonic_time()
  defp schedule_alert, do: Process.send_after(self(), :alert, :timer.seconds(15))
  defp diff(start), do: System.convert_time_unit(now() - start, :native, :second)
end
