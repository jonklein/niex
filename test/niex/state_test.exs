defmodule NiexWeb.StateTest do
  use Niex.DataCase

  test "creates a new with defaults" do
    state = Niex.State.new()
    assert(state.notebook.metadata[:name] == "Untitled Notebook")
  end

  test "loads from file" do
    state = Niex.State.from_file("test/fixtures/notebook.niex")

    assert(
      %Niex.Notebook{
        metadata: %{name: "Notebook File Fixture", version: "1.0"},
        worksheets: [
          %{cells: [%{cell_type: "code"}]}
        ]
      } = state.notebook
    )
  end

  test "loads from string" do
    state =
      Niex.State.from_string(
        '{"metadata":{"name":"Notebook String Fixture", "version":"1.0"},"worksheets":[{"cells":[{"cell_type":"code","content":["IO.inspect(\\"hello, world\\")"],"outputs":[{"text":""}],"prompt_number":0}]}]}'
      )

    assert(
      %Niex.Notebook{
        metadata: %{name: "Notebook String Fixture", version: "1.0"},
        worksheets: [
          %{cells: [%{cell_type: "code"}]}
        ]
      } = state.notebook
    )
  end

  test "adds a cell" do
    state = Niex.State.new()
    state = Niex.State.add_cell(state, 0, "markdown")

    assert(
      [%{cells: [%{cell_type: "markdown"}, %{cell_type: "code"}]}] = state.notebook.worksheets
    )
  end

  test "removes a cell" do
    state = Niex.State.new()
    state = Niex.State.remove_cell(state, 0)
    assert([%{cells: []}] = state.notebook.worksheets)
  end

  test "updates a cell" do
    state = Niex.State.new()
    state = Niex.State.update_cell(state, 0, %{content: ["new code"]})
    assert([%{cells: [%{content: ["new code"], cell_type: "code"}]}] = state.notebook.worksheets)
  end

  test "executes a cell and sets output" do
    state = Niex.State.new()
    state = Niex.State.update_cell(state, 0, %{content: ["IO.inspect(123)"]})
    state = Niex.State.execute_cell(state, 0)

    assert(
      [
        %{
          cells: [
            %{content: ["IO.inspect(123)"], cell_type: "code", outputs: [%{text: ["123"]}]}
          ]
        }
      ] = state.notebook.worksheets
    )
  end
end
