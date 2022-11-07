defmodule KobrakaiWeb.PortfolioController do
  use KobrakaiWeb, :controller
  alias Kobrakai.Portfolio

  def index(conn, _) do
    render(conn, :index, projects: Portfolio.all_projects())
  end

  def show(conn, %{"id" => id}) do
    project = Portfolio.get_project_by_id!(id)
    render(conn, :show, project: project, page_title: project.title)
  end
end
