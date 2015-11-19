defmodule IascTpSubastas.Router do
  use IascTpSubastas.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", IascTpSubastas do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    resources "/subastas", SubastaController, except: [:new, :edit]

    post "/subastas/:id/ofertas", SubastaController, :ofertar
  end

  # Other scopes may use custom stacks.
  # scope "/api", IascTpSubastas do
  #   pipe_through :api
  # end
end
