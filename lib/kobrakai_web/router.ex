defmodule KobrakaiWeb.Router do
  use KobrakaiWeb, :router
  import Redirect

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {KobrakaiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug KobrakaiWeb.Paths
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :rss do
    plug :accepts, ["html", "rss", "atom", "xml"]
    plug :put_root_layout, false
    plug :put_layout, false
  end

  scope "/", KobrakaiWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/projekte", PortfolioController, :index
    get "/projekte/:id", PortfolioController, :show
    get "/kolumne", BlogController, :index
    get "/kolumne/:id", BlogController, :show

    get "/werdegang", CustomController, :cv
    get "/kontakt", CustomController, :contact
    get "/impressum", CustomController, :legal
  end

  scope "/", KobrakaiWeb do
    pipe_through :rss

    get "/feed.xml", RssController, :rss
  end

  # Other scopes may use custom stacks.
  # scope "/api", KobrakaiWeb do
  #   pipe_through :api
  # end

  redirect "/digitaler-ikearahmen", "/projekte/digitaler-ikearahmen", :permanent
  redirect "/wunderle-partner-architekten", "/projekte/wunderle-partner-architekten", :permanent
  redirect "/sense", "/projekte/sense", :permanent
  redirect "/decrescendo", "/projekte/decrescendo", :permanent
  redirect "/korona-redesign", "/projekte/korona-redesign", :permanent
  redirect "/zombie-ad-infinitum", "/projekte/zombie-ad-infinitum", :permanent
  redirect "/maya", "/projekte/maya", :permanent
  redirect "/bleisatz", "/projekte/bleisatz", :permanent
  redirect "/schriftanalyse", "/projekte/schriftanalyse", :permanent

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:kobrakai, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: KobrakaiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
