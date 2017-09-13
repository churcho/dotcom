defmodule Site.Router do
  use Site.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  alias Site.StaticPage

  pipeline :browser do
    plug SystemMetrics.Plug
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_cookies
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Site.Plugs.Banner
    plug Turbolinks.Plug
    plug Site.Plugs.CommonFares
    plug Site.Plugs.Date
    plug Site.Plugs.DateTime
    plug Site.Plugs.RewriteUrls
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Site do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/events", EventController, only: [:index, :show] do
      get "/icalendar", IcalendarController, :show
    end
    resources "/news", NewsEntryController, only: [:index, :show]
    resources "/people", PersonController, only: [:show]
    resources "/projects", ProjectController, only: [:index, :show]
    get "/projects/:project_id/update/:id", ProjectController, :project_update
    get "/redirect/*path", RedirectController, :show
    resources "/stops", StopController, only: [:index, :show]
    get "/stops/*path", StopController, :stop_with_slash_redirect
    get "/schedules", ModeController, :index
    get "/schedules/subway", ModeController, :subway
    get "/schedules/bus", ModeController, :bus
    get "/schedules/ferry", ModeController, :ferry
    get "/schedules/commuter_rail", ModeController, :commuter_rail
    get "/schedules/Green/line", ScheduleV2Controller.Green, :line
    get "/schedules/Green/schedule", ScheduleV2Controller.Green, :trip_view
    get "/schedules/Green", ScheduleV2Controller.Green, :show
    get "/schedules/:route/timetable", ScheduleV2Controller.TimetableController, :show, as: :timetable
    get "/schedules/:route/schedule", ScheduleV2Controller.TripViewController, :show, as: :trip_view
    get "/schedules/:route/line", ScheduleV2Controller.LineController, :show, as: :line
    get "/schedules/:route", ScheduleV2Controller, :show, as: :schedule
    get "/schedules/:route/pdf", ScheduleV2Controller.Pdf, :pdf, as: :route_pdf
    get "/style_guide", StyleGuideController, :index
    get "/style_guide/:section", StyleGuideController, :index
    get "/style_guide/:section/:subpage", StyleGuideController, :show
    get "/transit-near-me", TransitNearMeController, :index
    resources "/alerts", AlertController, only: [:index, :show]
    get "/trip_planner", TripPlanController, :index
    get "/customer-support", CustomerSupportController, :index
    get "/customer-support/thanks", CustomerSupportController, :thanks
    post "/customer-support", CustomerSupportController, :submit
    get "/fares/commuter_rail/zone", FareController, :zone
    resources "/fares", FareController, only: [:index, :show]
    resources "/how-to-pay", HowToPayController, only: [:index, :show], param: "mode"
    get "/search", SearchController, :index
    for static_page <- StaticPage.static_pages do
      get "/#{StaticPage.convert_path(static_page)}", StaticPageController, static_page
    end
    get "/sites/*path", StaticFileController, :index
  end

  scope "/", Site do
    get "/uploadedfiles/*path", OldSiteRedirectController, :uploaded_files
    get "/uploadedFiles/*path", OldSiteRedirectController, :uploaded_files
    get "/uploadedimages/*path", OldSiteRedirectController, :uploaded_files
    get "/uploadedImages/*path", OldSiteRedirectController, :uploaded_files
    get "/images/*path", OldSiteRedirectController, :uploaded_files
    get "/lib/*path", OldSiteRedirectController, :uploaded_files
    get "/gtfs_archive/archived_feeds.txt", OldSiteRedirectController, :archived_files
    get "/schedules_and_maps", OldSiteRedirectController, :schedules_and_maps
    get "/schedules_and_maps/*path", OldSiteRedirectController, :schedules_and_maps
    get "/about_the_mbta/public_meetings", Redirector, to: "/events"
    get "/about_the_mbta/news_events", Redirector, to: "/news"
  end

  scope "/_flags" do
    pipe_through [:browser]

    forward "/", Laboratory.Router
  end

  scope "/", Site do
    get "/*path", ContentController, :index
  end
end
