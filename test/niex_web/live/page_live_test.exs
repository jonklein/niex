defmodule NiexWeb.PageLiveTest do
  use NiexWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, view, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Untitled Notebook"
    assert render(view) =~ "Untitled Notebook"
  end

  test "initial state", %{conn: conn} do
    {:ok, view, _} = live(conn, "/")
    assert render(view) =~ "In [0]"
  end

  test "edit cells", %{conn: conn} do
    {:ok, view, _} = live(conn, "/")
    assert render_click(view, "add-cell", %{"type" => "code", "index" => "0"}) =~ "In [1]"
  end
end
