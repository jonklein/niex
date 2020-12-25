defmodule Niex do
  @moduledoc """
  Top-level public-facing Niex functions used in notebooks.
  """

  @doc """
  Sends a message to render the provided `content`, which can be a
  text string, or a `Niex.Content` struct.

  When executed from within a notebook code cell, the cell is updated
  immediately with the content.  This allows for animation in cells by
  making repeated calls to `render`.
  """
  def render(content) do
    send(Process.group_leader(), {:render, content})
    content
  end
end
