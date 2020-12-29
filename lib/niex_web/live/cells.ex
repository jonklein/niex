defmodule NiexWeb.Cells do
  @moduledoc false

  use Phoenix.LiveComponent
  import Phoenix.HTML

  def render(
        assigns = %{
          selected: true,
          cell: %{cell_type: "markdown"}
        }
      ) do
    ~L"""
    <div class="cell markdown"  class="cell"  phx-value-ref="<%= @cell.id %>" phx-blur="blur-cell">
      <form phx-change="update-content" phx-blur="blur-cell" phx-value-ref="<%= @cell.id %>">
        <input type="hidden" name="ref" value="<%= @cell.id %>" />
        <input type="hidden" name="cell_type" value="markdown" />
        <textarea autofocus phx-blur="blur-cell" phx-value-ref="<%= @cell.id %>" phx-focus="focus-cell" name="text" phx-hook="NiexEditor" id="cell-text-<%= @cell.id %>"><%= @cell[:content] %></textarea>
      </form>
      <div class="toolbar">
        <button class="remove" phx-click="remove-cell" phx-value-ref="<%= @cell.id %>">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    """
  end

  def render(
        assigns = %{
          cell: %{
            cell_type: "markdown"
          }
        }
      ) do

    case Earmark.as_html(Enum.join(assigns[:cell][:content], "\n")) do
      {:ok, html, _}  -> render_markdown(html, assigns)
      {:error, _, messages} -> render_error(messages, assigns)
    end
  end

  def render(
        assigns = %{
          cell: %{
            cell_type: "code"
          }
        }
      ) do
    ~L"""
      <div class="cell">
        <div class="cell-row">
          <span class="gutter">
            In [<%= @cell[:prompt_number] %>]:
          </span>
        <div class="content">
          <form phx-submit="noop" phx-change="update-content">
           <input type="hidden" name="ref" value="<%= @cell.id %>" />
           <input type="hidden" name="cell_type" value="code" />
          <textarea spellcheck="false" autofocus phx-blur="blur-cell" phx-click="focus-cell" phx-value-ref="<%= @cell.id %>" phx-hook="NiexCodeEditor" name="text" id="cell-code-<%= @cell.id %>"><%= Enum.join(@cell[:content], "\n") %></textarea>
         </form>
          <%= if @selected do %>
            <div class="toolbar">
            <button class="run" phx-click="execute-cell" phx-value-ref="<%= @cell.id %>">
              <i class="fas fa-play"></i>
            </button>
            <button class="remove" phx-click="remove-cell" phx-value-ref="<%= @cell.id %>">
              <i class="fas fa-trash"></i>
            </button>
           </div>
        <% end %>

      </div>
      </div>
      <div class="cell-row">
        <span class="gutter">
            Out [<%= @cell[:prompt_number] %>]:
        </span>
        <span class="content">
          <div class="out">
            <%= raw(Enum.join(Enum.map(@cell[:outputs], & &1[:text]), "\n")) %>
          </div>
        </span>
        </div>
      </div>
    </pre>
    """
  end

  defp render_error( messages,
        assigns = %{
          cell: %{}
        }) do
    message_text =
      messages
      |> Enum.map(&inspect(&1))
      |> Enum.join("\n")
    ~L"""
    <div class="cell markdown" phx-click="focus-cell" phx-blur="blur-cell" class="cell" phx-value-ref="<%= @cell.id %>">
      <div class="content"><%= message_text %></div>
    </div>
    """
  end

  defp render_markdown( html, 
        assigns = %{
          cell: %{}
        }) do
    ~L"""
    <div class="cell markdown" phx-click="focus-cell" phx-blur="blur-cell" class="cell" phx-value-ref="<%= @cell.id %>">
      <div class="content"><%= raw(html) %></div>
    </div>
    """
  end
end
