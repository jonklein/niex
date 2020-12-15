defmodule Niex.Notebook do
  def default_title do
    "Untitled Notebook"
  end

  def input_cell(state, idx) do
    Enum.at(state.notebook["worksheets"], state.worksheet)["cells"] |> Enum.at(idx)
  end

  def update_metadata(state, metadata) do
    %{state | dirty: true, notebook: %{state.notebook | "metadata" => metadata}}
  end

  def add_cell(state, cell_type) do
    worksheet = Enum.at(state.notebook["worksheets"], state.worksheet)

    idx = state.selected_cell || length(worksheet["cells"])

    cells =
      List.insert_at(worksheet["cells"], idx, %{
        "cell_type" => cell_type,
        "input" => [""],
        "outputs" => [%{"text" => ""}]
      })

    worksheets =
      List.replace_at(state.notebook["worksheets"], state.worksheet, %{
        worksheet
        | "cells" => cells
      })

    %{
      state
      | dirty: true,
        notebook: %{state.notebook | "worksheets" => worksheets},
        selected_cell: nil
    }
  end

  def remove_cell(state) do
    worksheet = Enum.at(state.notebook["worksheets"], state.worksheet)
    cells = List.delete_at(worksheet["cells"], state.selected_cell)

    worksheets =
      List.replace_at(state.notebook["worksheets"], state.worksheet, %{
        worksheet
        | "cells" => cells
      })

    %{
      state
      | dirty: true,
        notebook: %{state.notebook | "worksheets" => worksheets},
        selected_cell: nil
    }
  end

  def update_cell(state, idx, update) do
    cell = input_cell(state, idx)

    %{
      state
      | notebook:
          update_cell(
            state.notebook,
            state.worksheet,
            idx,
            Map.merge(cell, update)
          ),
        dirty: true
    }
  end

  def execute_cell(state, socket, idx, input) do
    cell = input_cell(state, idx)
    {output, bindings} = Niex.Eval.start_link(input, state.bindings)

    %{
      update_cell(state, idx, %{"input" => [input], "outputs" => outputs(socket, output)})
      | bindings: bindings
    }
  end

  def outputs(_, output = %Niex.Content{}) do
    [%{"text" => Niex.Content.render(output)}]
  end

  def outputs(_, output = %Contex.Plot{}) do
    {:safe, svg} = Contex.Plot.to_svg(output)
    [%{"text" => svg}]
  end

  def outputs(_, output) do
    [%{"text" => [inspect(output)]}]
  end

  def update_cell(notebook, worksheet_idx, idx, value) do
    worksheet = Enum.at(notebook["worksheets"], worksheet_idx)

    %{
      notebook
      | "worksheets" =>
          List.replace_at(
            notebook["worksheets"],
            worksheet_idx,
            %{
              worksheet
              | "cells" => List.replace_at(worksheet["cells"], idx, value)
            }
          )
    }
  end
end
