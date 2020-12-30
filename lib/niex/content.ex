defmodule Niex.Content do
  defstruct(content: nil, type: nil)

  @moduledoc """
  Content that can be rendered within a cell in a Niex notebook when
  returned (or rendered via `Niex.render/1`) in a notebook cell.
  """

  @doc """
  Builds content for a cell containing an image at the provided `url`.
  """
  def image(url) do
    %Niex.Content{type: "image", content: url}
  end

  @doc """
  Builds content for a video containing an image at the provided `url`.
  """
  def video(url, options \\ []) do
    %Niex.Content{
      type: "video",
      content: %{url: url, options: Enum.into(options, %{width: 480, height: 360})}
    }
  end

  @doc """
  Returns content for a cell containing a chart using the Chartkick library.

  The `type` of the chart corresponds to the chart type as shown in the
  [ChartKick docs](https://github.com/ankane/chartkick.js).
  """
  def chart(type, data, options \\ []) do
    %Niex.Content{
      type: "chart",
      content: %{type: type, data: data, options: Enum.into(options, %{width: 480, height: 360})}
    }
  end

  @doc """
  Builds content for a cell containing plain HTML
  """
  def html(content) do
    %Niex.Content{type: "html", content: content}
  end

  @doc """
  Builds content for a cell containing preformatted text
  """
  def pre(content) do
    %Niex.Content{type: "pre", content: content}
  end

  @doc """
  Renders the provided `Niex.Content` into HTML
  """
  def render(%Niex.Content{type: "chart", content: data}) do
    """
    <div class="chart" style="width: #{data.options.width}px; height: #{data.options.height}px" phx-hook="NiexChart" data-chart='#{
      Poison.encode!(data)
    }' id="#{UUID.uuid4()}}" />
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

  def render(%Niex.Content{type: "pre", content: content}) do
    """
    <pre>#{content}</pre>
    """
  end

  def render(%Niex.Content{type: "html", content: content}) do
    content
  end
end
