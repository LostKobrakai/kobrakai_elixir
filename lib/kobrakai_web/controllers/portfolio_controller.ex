defmodule KobrakaiWeb.PortfolioController do
  use KobrakaiWeb, :controller
  alias Kobrakai.Portfolio

  def index(conn, _) do
    conn
    |> merge_open_graph(title: "Projekte")
    |> render(:index, projects: Portfolio.all_projects())
  end

  def show(conn, %{"id" => id}) do
    project = Portfolio.get_project_by_id!(id)

    conn
    |> merge_open_graph(title: project.title)
    |> render(:show, project: project)
  end
end
