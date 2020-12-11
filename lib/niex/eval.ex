defmodule Niex.Eval do
  def alias!(x) do
    x |> IO.inspect()
    123
  end

  def test(x) do
    IO.inspect(x)
  end
end
