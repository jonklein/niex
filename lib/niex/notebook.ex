defmodule Niex.Notebook do
  def default_title do
    "Untitled Notebook"
  end

  def input_cell(state, idx) do
    Enum.at(state.notebook[:worksheets], state.worksheet)[:cells] |> Enum.at(idx)
  end

  def update_metadata(state, metadata) do
    %{state | dirty: true, notebook: %{state.notebook | metadata: metadata}}
  end

  def add_cell(state, cell_type, idx) do
    worksheet = Enum.at(state.notebook[:worksheets], state.worksheet)

    prompt_number =
      Enum.slice(worksheet[:cells], 0, idx)
      |> Enum.filter(&(&1[:cell_type] == cell_type))
      |> length

    cells =
      List.insert_at(worksheet[:cells], idx, %{
        prompt_number: prompt_number,
        cell_type: cell_type,
        content: [default_content(cell_type)],
        outputs: [%{text: ""}]
      })

    worksheets =
      List.replace_at(state.notebook["worksheets"], state.worksheet, %{
        worksheet
        | cells: renumber_code_cells(cells)
      })

    %{
      state
      | dirty: true,
        notebook: %{state.notebook | worksheets: worksheets},
        selected_cell: nil
    }
  end

  def remove_cell(state) do
    worksheet = Enum.at(state.notebook[:worksheets], state.worksheet)
    cells = List.delete_at(worksheet[:cells], state.selected_cell)

    worksheets =
      List.replace_at(state.notebook[:worksheets], state.worksheet, %{
        worksheet
        | cells: renumber_code_cells(cells)
      })

    %{
      state
      | dirty: true,
        notebook: %{state.notebook | worksheets: worksheets},
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

  def execute_cell(state, socket, idx) do
    cell = input_cell(state, idx)
    {output, bindings} = Niex.Eval.start_link(Enum.join(cell[:content], "\n"), state.bindings)

    %{
      update_cell(state, idx, %{outputs: outputs(socket, output)})
      | bindings: bindings
    }
  end

  def outputs(_, output = %Niex.Content{}) do
    [%{text: Niex.Content.render(output)}]
  end

  def outputs(_, output = %Contex.Plot{}) do
    {:safe, svg} = Contex.Plot.to_svg(output)
    [%{text: svg}]
  end

  def outputs(_, output) do
    [%{text: [inspect(output)]}]
  end

  def update_cell(notebook, worksheet_idx, idx, value) do
    worksheet = Enum.at(notebook[:worksheets], worksheet_idx)

    %{
      notebook
      | worksheets:
          List.replace_at(
            notebook[:worksheets],
            worksheet_idx,
            %{
              worksheet
              | cells: List.replace_at(worksheet[:cells], idx, value)
            }
          )
    }
  end

  defp renumber_code_cells(list, idx \\ 0)

  defp renumber_code_cells([first | rest], idx) do
    if first["cell_type"] == "code" do
      [%{first | "prompt_number" => idx} | renumber_code_cells(rest, idx + 1)]
    else
      [first | renumber_code_cells(rest, idx)]
    end
  end

  defp renumber_code_cells([], _) do
    []
  end

  defp default_content("code") do
  end

  defp default_content("markdown") do
    "# Header\ncontent"
  end
end
