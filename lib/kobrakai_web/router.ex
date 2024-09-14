defmodule KobrakaiWeb.Router do
  use KobrakaiWeb, :router
  import Phoenix.LiveDashboard.Router
  import PhoenixStorybook.Router
  import Redirect
  import KobrakaiWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {KobrakaiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_current_path
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :rss do
    plug :accepts, ["html", "rss", "atom", "xml"]
    plug :put_root_layout, false
    plug :put_layout, false
  end

  pipeline :webfinger do
    plug :accepts, ["jrd", "json"]
  end

  pipeline :admin do
    plug :auth
  end

  scope "/", KobrakaiWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/projekte", PortfolioController, :index
    get "/projekte/:id", PortfolioController, :show
    get "/kolumne", BlogController, :index
    get "/kolumne/:id", BlogController, :show

    get "/photography", CustomController, :photography
    get "/werdegang", CustomController, :cv
    get "/kontakt", CustomController, :contact
    get "/impressum", CustomController, :legal

    scope "/scratchpad" do
      get "/", ScratchpadController, :index
      live "/checkboxes", Scratchpad.Checkboxes
      live "/table", Scratchpad.Table
    end
  end

  scope "/", KobrakaiWeb do
    pipe_through :rss

    get "/feed.xml", RssController, :rss
  end

  scope "/", KobrakaiWeb do
    pipe_through :webfinger

    get "/.well-known/webfinger", WebfingerController, :finger
  end

  scope "/image" do
    forward "/", KobrakaiWeb.ImagePlug,
      secret: &KobrakaiWeb.fetch_secret/0,
      finch: Kobrakai.Finch
  end

  scope "/ws", KobrakaiWeb do
    get "/connection_timer/:name", WebsocketUpgrade, KobrakaiWeb.ConnectionTimer
  end

  scope "/", KobrakaiWeb do
    pipe_through [:browser, :admin]

    live_dashboard "/dashboard", metrics: KobrakaiWeb.Telemetry
  end

  scope "/" do
    storybook_assets()
  end

  scope "/", KobrakaiWeb do
    pipe_through [:browser, :admin]
    live_storybook("/storybook", backend_module: KobrakaiWeb.Storybook)
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
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  defp auth(conn, _opts) do
    case Application.fetch_env!(:kobrakai, :admin) do
      false -> conn
      config -> Plug.BasicAuth.basic_auth(conn, config)
    end
  end
end
