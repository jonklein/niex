defmodule NiexWeb.Router do
  @moduledoc false

  use NiexWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {NiexWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", NiexWeb do
    pipe_through(:browser)

    live("/", PageLive, :index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", NiexWeb do
  #   pipe_through :api
  # end
end
