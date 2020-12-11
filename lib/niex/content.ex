defmodule Niex.Content do
  defstruct(content: nil, type: nil)

  def image(url) do
    %Niex.Content{type: "image", content: url}
  end

  def render(%Niex.Content{type: "image", content: url}) do
    """
      <img src="#{url}" />
    """
  end
end
