defmodule MazaoDaktariWeb.Router do
  use MazaoDaktariWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", MazaoDaktariWeb do
    pipe_through :api

    get "/health", DiagnosisController, :health
    post "/diagnose", DiagnosisController, :diagnose
  end
end
