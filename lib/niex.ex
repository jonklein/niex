defmodule Niex do
  @moduledoc """
  """

  def render(i) do
    send(Process.group_leader(), {:render, i})
    i
  end
end
