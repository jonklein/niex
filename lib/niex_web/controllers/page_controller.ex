defmodule NiexWeb.PageController do
  @moduledoc false

  use NiexWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
