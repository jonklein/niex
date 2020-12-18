defmodule NiexWeb.PageLiveTest do
  use NiexWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Untitled Notebook"
    assert render(page_live) =~ "Untitled Notebook"
  end
end
