defmodule NiexWeb.CellSeparator do
  @moduledoc false

  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
      <div class="cell-separator">
        <div class="dropdown">
            <span class="icon">
                <i size="50" class="fas fa-plus-square"></i>
            </span>
            <div class="dropdown-items">
                <a phx-click="add-cell" phx-value-index="<%= @index %>" phx-value-type="code" class="item">Code</a>
                <a phx-click="add-cell" phx-value-index="<%= @index %>" phx-value-type="markdown" class="item">Markdown</a>
            </div>
        </div>
    </div>
    """
  end
end
