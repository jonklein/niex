defmodule Niex.Notebook do
  import Kernel, except: [alias!: 1]

  def input_cell(notebook, worksheet, idx) do
    Enum.at(notebook["worksheets"], worksheet)["cells"] |> Enum.at(idx)
  end

  def update_metadata(state, metadata) do
    %{state | dirty: true, notebook: %{state.notebook | "metadata" => metadata}}
  end

  def add_cell(state) do
    worksheet = Enum.at(state.notebook["worksheets"], state.worksheet)

    cells =
      List.insert_at(worksheet["cells"], state.selected_cell, %{
        cell_type: "markdown"
      })
      |> IO.inspect()

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
    cell = input_cell(state.notebook, state.worksheet, idx)

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

  def execute_cell(state, idx, input) do
    cell = input_cell(state.notebook, state.worksheet, idx)
    {output, bindings} = eval(input, state.bindings)

    %{
      update_cell(state, idx, %{"input" => [input], "outputs" => outputs(output)})
      | bindings: bindings
    }
  end

  def outputs(output = %Niex.Content{}) do
    [%{"text" => Niex.Content.render(output)}]
  end

  def outputs(output = %Contex.Plot{}) do
    {:safe, svg} = Contex.Plot.to_svg(output)
    [%{"text" => svg}]
  end

  def outputs(output) do
    [%{"text" => [inspect(output)]}]
  end

  def eval(input, bindings) do
    try do
      Code.eval_string(input, bindings, functions: [{Niex.Eval, [alias: 1]}])
    rescue
      err ->
        {err, bindings}
    end
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
