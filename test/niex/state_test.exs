defmodule Niex.StateTest do
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

  test "renumbers code cell" do
    state = Niex.State.new()
    state = Niex.State.add_cell(state, 0, "markdown")
    state = Niex.State.add_cell(state, 0, "code")
    state = Niex.State.add_cell(state, 0, "code")

    assert(
      Enum.at(state.notebook.worksheets, 0).cells |> Enum.map(& &1[:prompt_number]) == [
        0,
        1,
        nil,
        2
      ]
    )
  end

  test "removes a cell" do
    state = Niex.State.new()
    [cell] = Enum.at(state.notebook.worksheets, 0).cells
    state = Niex.State.remove_cell(state, cell.id)
    assert([%{cells: []}] = state.notebook.worksheets)
  end

  test "updates a cell" do
    state = Niex.State.new()
    [cell] = Enum.at(state.notebook.worksheets, 0).cells

    state = Niex.State.update_cell(state, cell.id, %{content: ["new code"]})
    assert([%{cells: [%{content: ["new code"], cell_type: "code"}]}] = state.notebook.worksheets)
  end

  test "executes a cell and sets outputs & bindings" do
    state = Niex.State.new()
    [cell] = Enum.at(state.notebook.worksheets, 0).cells

    state =
      Niex.State.update_cell(state, cell.id, %{content: ["Niex.render(0)\nx = IO.inspect(1)"]})

    # Execute cell, then expect a series of
    Niex.State.execute_cell(state, cell.id, self())

    # First message: set output to 0 from Niex.render
    receive do
      {:command_output, id, update} ->
        assert(id == cell.id)
        assert(%{outputs: [%{text: ["0"]}]} = Map.merge(cell, update))
    end

    # Second message: set output to 1 from result
    receive do
      {:command_output, id, update} ->
        assert(id == cell.id)
        assert(%{outputs: [%{text: ["1"]}]} = Map.merge(cell, update))
    end

    # Third message: set bindings to [x: 1]
    receive do
      {:command_bindings, bindings} ->
        assert(bindings == [x: 1])
    end

    # Last message: set env to something
    receive do
      {:command_env, env} ->
        assert(env != nil)
    end
  end
end
