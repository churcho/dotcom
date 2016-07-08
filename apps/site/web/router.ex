defmodule Site.Router do
  use Site.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Site do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/redirect/:path", RedirectController, :show
    resources "/stations", StationController, only: [:index, :show]
    get "/schedules/subway", ScheduleController, :subway
    get "/schedules/bus", ScheduleController, :bus
    get "/schedules/boat", ScheduleController, :boat
    get "/schedules/commuter-rail", ScheduleController, :commuter_rail
    resources "/schedules", ScheduleController, only: [:index]
    get "/alerts", ScheduleController, :alerts
    get "/alerts/:alert", ScheduleController, :alerts
  end

  # Other scopes may use custom stacks.
  # scope "/api", Site do
  #   pipe_through :api
  # end
end
