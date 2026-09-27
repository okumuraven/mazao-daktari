defmodule MazaoDaktariWeb.Router do
  use MazaoDaktariWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug MazaoDaktariWeb.Plugs.Auth, :fetch_current_user
  end

  pipeline :authenticated do
    plug MazaoDaktariWeb.Plugs.Auth, :require_user
  end

  scope "/api", MazaoDaktariWeb do
    pipe_through :api

    get "/health", DiagnosisController, :health
    post "/diagnose", DiagnosisController, :diagnose
    post "/auth/google", AuthController, :google

    scope "/" do
      pipe_through :authenticated

      get "/me", AuthController, :me
      get "/diagnoses", DiagnosesController, :index
    end
  end
end
