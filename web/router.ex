defmodule Gt.Router do
  use Gt.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NavigationHistory.Tracker, excluded_paths: [~r(^/login), ~r(^/auth)]
  end

  # This plug will look for a Guardian token in the session in the default location
  # Then it will attempt to load the resource found in the JWT.
  # If it doesn't find a JWT in the default location it doesn't do anything
  pipeline :browser_auth do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
    plug Gt.Plug.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Gt do
    pipe_through [:browser, :browser_auth]

    get "/login", SessionController, :new, as: :login
    get "/login/:identity", SessionController, :new
    post "/auth/:identity/callback", SessionController, :callback
    post "/auth/sms", SessionController, :sms
    post "/auth/sms/resend", SessionController, :sms_resend
    post "/auth/google", SessionController, :google
    get "/logout", SessionController, :logout
    delete "/logout", SessionController, :logout, as: :logout
    get "/locale/:locale", SessionController, :locale

    get "/", DashboardController, :index
    post "/", DashboardController, :index

    scope "/dashboard" do
      post "/daily/:metrics/:id", DashboardController, :chart_daily
      post "/monthly/:metrics/:id", DashboardController, :chart_monthly
    end

    scope "/finance" do
      scope "/payment-systems" do
        resources "/", PaymentSystemController, except: [:show, :new, :create]
        get "/new/:type", PaymentSystemController, :new
        post "/:type", PaymentSystemController, :create
      end
      scope "/payment-check" do
        resources "/", PaymentCheckController, except: [:edit, :update, :show]
        get "/:id", PaymentCheckController, :show
        post "/:id", PaymentCheckController, :show
        post "/:id/start", PaymentCheckController, :start
        post "/:id/stop", PaymentCheckController, :stop
        post "/:id/1gp-errors", PaymentCheckController, :one_gamepay_errors
        post "/:id/gs-errors", PaymentCheckController, :gameserver_errors
      end
      scope "/funds" do
        get "/", FundsReportController, :index
        post "/", FundsReportController, :index
      end
      scope "/monthly-balances" do
        get "/", MonthlyBalancesController, :index
        post "/", MonthlyBalancesController, :index
      end
    end

    scope "/statistics" do
      scope "/consolidated" do
        get "/", ConsolidatedReportController, :index
        post "/", ConsolidatedReportController, :index
      end
      scope "/ltv" do
        get "/", LtvReportController, :index
        post "/", LtvReportController, :index
      end
      scope "/segments" do
        get "/", SegmentsReportController, :index
        post "/", SegmentsReportController, :index
      end
      scope "/retentions" do
        get "/", RetentionsReportController, :index
        post "/", RetentionsReportController, :index
      end
      scope "/timeline" do
        get "/", TimelineReportController, :index
        post "/", TimelineReportController, :index
      end
      scope "/cohorts" do
        get "/", CohortsReportController, :index
        post "/", CohortsReportController, :index
      end
      scope "/universal" do
        get "/", UniversalReportController, :index
        post "/", UniversalReportController, :index
      end
    end

    scope "/calendar" do
      scope "/events" do
        resources "/", CalendarEventController, except: [:show]
        get "/search", CalendarEventController, :search
      end
      resources "/types", CalendarTypeController, except: [:show]
      resources "/groups", CalendarGroupController, except: [:show]
    end

    scope "/players" do
      scope "/multiaccounts" do
        get "/", MultiaccountsController, :index
        post "/", MultiaccountsController, :index
      end
      resources "/signup-channels", SignupChannelController, except: [:show]
    end

    scope "/settings" do
      scope "/users" do
        get "/search", UserController, :search
        resources "/", UserController, except: [:delete, :show]
      end
      scope "/projects" do
        get "/search", ProjectController, :search
        resources "/", ProjectController, except: [:delete, :show]
      end
      scope "/permissions" do
        get "/", PermissionsController, :index
        post "/", PermissionsController, :index
        get "/export", PermissionsController, :export
      end
      scope "/data-sources" do
        resources "/", DataSourceController, except: [:show, :new, :create]
        get "/new/:type", DataSourceController, :new
        post "/:type", DataSourceController, :create
        post "/:id/start", DataSourceController, :start
        post "/:id/stop", DataSourceController, :stop
      end
      scope "/cache" do
        resources "/", CacheController, except: [:show, :new, :create]
        get "/new/:type", CacheController, :new
        post "/:type", CacheController, :create
        post "/:id/start", CacheController, :start
        post "/:id/stop", CacheController, :stop
      end
      scope "/smtp" do
        resources "/", SmtpServerController, except: [:show]
      end
    end

  end

  # Other scopes may use custom stacks.
  # scope "/api", Gt do
  #   pipe_through :api
  # end
end
