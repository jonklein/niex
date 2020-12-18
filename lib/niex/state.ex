defmodule Niex.State do
  defstruct(
    notebook: %Niex.Notebook{},
    selected_cell: nil,
    worksheet: 0,
    bindings: [],
    path: nil,
    dirty: false
  )

  def new() do
    %Niex.State{
      dirty: true,
      notebook: %Niex.Notebook{
        metadata: %{name: "Untitled Notebook"},
        worksheets: [
          %{
            cells: [
              %{
                prompt_number: 0,
                cell_type: "code",
                content: ["IO.inspect(\"hello, world\")"],
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

  def update_metadata(state, metadata) do
    %{state | dirty: true, notebook: %{state.notebook | metadata: metadata}}
  end

  def add_cell(state, idx, cell_type) do
    %{
      state
      | notebook: Niex.Notebook.add_cell(state.notebook, state.worksheet, idx, cell_type),
        dirty: true
    }
  end

  def remove_cell(state, idx) do
    %{
      state
      | notebook: Niex.Notebook.remove_cell(state.notebook, state.worksheet, idx),
        dirty: true
    }
  end

  def update_cell(state, idx, update) do
    %{
      state
      | notebook:
          Niex.Notebook.update_cell(
            state.notebook,
            state.worksheet,
            idx,
            update
          ),
        dirty: true
    }
  end

  def execute_cell(state, idx) do
    {notebook, bindings} =
      Niex.Notebook.execute_cell(state.notebook, state.worksheet, idx, state.bindings)

    %{
      state
      | notebook: notebook,
        bindings: bindings,
        dirty: true
    }
  end

  def set_selected_cell(state, n) do
    %{state | selected_cell: n}
  end

  def active_worksheet(state) do
    Enum.at(state.notebook.worksheets, state.worksheet)
  end
end
