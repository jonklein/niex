defmodule Niex.Content do
  defstruct(content: nil, type: nil)

  @doc """
  Returns content for a cell containing an image at the provided `url`.
  """
  def image(url) do
    %Niex.Content{type: "image", content: url}
  end

  @doc """
  Returns content for a video containing an image at the provided `url`.
  """
  def video(url, options \\ [width: 480, height: 360]) do
    %Niex.Content{type: "video", content: %{url: url, options: Enum.into(options, %{})}}
  end

  @doc """
  Returns content for a cell containing a chart using the Chartkick library.

  The `type` of the chart corresponds to the chart type as shown in the
  [ChartKick docs](https://github.com/ankane/chartkick.js).
  """
  def chart(type, data, options \\ []) do
    %Niex.Content{
      type: "chart",
      content: %{type: type, data: data, options: Enum.into(options, %{})}
    }
  end

  def render(%Niex.Content{type: "chart", content: data}) do
    """
    <div phx-hook="NiexChart" data-chart='#{Poison.encode!(data)}' id="#{UUID.uuid4()}}" />
    """
  end

  def render(%Niex.Content{type: "image", content: url}) do
    """
    <img src="#{url}" />
    """
  end

  def render(%Niex.Content{type: "video", content: %{url: url, options: options}}) do
    """
    <video controls width="#{options[:width]}" height="#{options[:height]}" src="#{url}" />
    """
  end
end
