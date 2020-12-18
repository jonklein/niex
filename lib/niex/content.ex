defmodule Niex.Content do
  defstruct(content: nil, type: nil)

  def image(url) do
    %Niex.Content{type: "image", content: url}
  end

  """
  Renders a chart using the Chartkick library.
  """

  def chart(type, data, options \\ []) do
    %Niex.Content{
      type: "chart",
      content: %{type: type, data: data, options: Enum.into(options, %{})}
    }
  end

  def line_chart(type, data, options \\ []) do
    chart("LineChart", data, options)
  end

  def render(%Niex.Content{type: "chart", content: data}) do
    """
    <div phx-hook="NiexChart" data-chart='#{Jason.encode!(data)}' id="#{UUID.uuid4()}}" />
    """
  end

  def render(%Niex.Content{type: "image", content: url}) do
    """
    <img src="#{url}" />
    """
  end
end
