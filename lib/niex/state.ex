defmodule Niex.State do
  defstruct(
    notebook: %{},
    selected_cell: nil,
    worksheet: 0,
    bindings: [],
    path: nil,
    dirty: false
  )

  def new() do
    %Niex.State{
      notebook: %{
        metadata: %{name: "Untitled Notebook"},
        worksheets: [
          %{
            cells: [
              %{
                prompt_number: 0,
                cell_type: "code",
                content: ["IO.puts(\"hello, world\")"],
                outputs: [%{"text" => ""}]
              }
            ]
          }
        ]
      }
    }
  end

  def from_file(path) do
    %{from_string(File.read!(path)) | path: path}
  end

  def from_string(str) do
    %Niex.State{notebook: Jason.decode!(str, keys: :atoms)}
  end

  def save(state, path) do
    save(%{state | path: path})
  end

  def save(state = %Niex.State{path: path}) when not is_nil(path) do
    :ok = File.write(path, Jason.encode!(state.notebook))
    %{state | dirty: false}
  end

  def save(_) do
  end

  def set_selected_cell(state, n) do
    %{state | selected_cell: n}
  end

  def active_worksheet(state) do
    Enum.at(state.notebook[:worksheets], state.worksheet)
  end
end
