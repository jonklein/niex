defmodule NiexWeb.PageController do
  use NiexWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
