defmodule KobrakaiWeb.ScratchpadHTML do
  use KobrakaiWeb, :html

  def index(assigns) do
    ~H"""
    <div>
      <h2 class="uppercase mb-6"><%= @page_title %></h2>
      <div class="sm:columns-2 lg:columns-3">
        <ol class="-my-4">
          <KobrakaiWeb.PageHTML.list_item
            :for={{pad, index} <- @pads |> Enum.reverse() |> Enum.with_index()}
            class={"opacity-0 animate-in animation-fill-mode-forwards animation-delay-#{index * 55}"}
            headline={pad.name}
            date={pad.date}
            url={~p"/scratchpad/#{pad.id}"}
          />
        </ol>
      </div>
    </div>
    """
  end
end
