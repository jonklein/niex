defmodule Niex.Notebook do
  @moduledoc """
  Interface to the Notebook data.  Generally not used directly - instead, use the
  functions in Niex.State to manipute the full app state including the notebook.
  """

  defstruct(
    worksheets: [%{cells: []}],
    metadata: %{name: "", version: "1.0"}
  )

  @doc """
  The default notebook title.
  """
  def default_title do
    "Untitled Notebook"
  end

  @doc """
  Updates the notebook metadata which contains `name` and `version` strings.
  """
  def update_metadata(notebook, metadata) do
    %{notebook | metadata: metadata}
  end

  @doc """
  Adds a cell to the `notebook` with the specified `worksheet_idx`, `cell_idx` and `cell_type`,
  returns the updated notebook.
  """
  def add_cell(notebook, worksheet_idx, cell_idx, cell_type) do
    worksheet = Enum.at(notebook.worksheets, worksheet_idx)

    cells =
      List.insert_at(worksheet.cells, cell_idx, %{
        prompt_number: nil,
        id: UUID.uuid4(),
        cell_type: cell_type,
        content: [default_content(cell_type)],
        outputs: [%{text: ""}]
      })

    worksheets =
      List.replace_at(notebook.worksheets, worksheet_idx, %{
        worksheet
        | cells: renumber_code_cells(cells)
      })

    %{notebook | worksheets: worksheets}
  end

  @doc """
  Removes the cell with the specified `id` from the `notebook`, returns
  the updated notebook.
  """
  def remove_cell(notebook, id) do
    {worksheet_idx, index} = cell_path(notebook, id)

    worksheet = Enum.at(notebook.worksheets, worksheet_idx)
    cells = List.delete_at(worksheet.cells, index)

    worksheets =
      List.replace_at(notebook.worksheets, worksheet_idx, %{
        worksheet
        | cells: renumber_code_cells(cells)
      })

    %{notebook | worksheets: worksheets}
  end

  @doc """
  Executes the Elixir code cell of a `notebook` worksheet at `worksheet_idx` at the provided `index`
  """
  def execute_cell(notebook, id, output_pid, bindings, env) do
    {worksheet, index} = cell_path(notebook, id)

    cell = cell(notebook, worksheet, index)
    cmd = Enum.join(cell.content, "\n")

    Niex.Eval.AsyncEval.eval_string(output_pid, cell.id, cmd, bindings, env)

    update_cell(notebook, id, %{running: true})
  end

  @doc """
  Replaces the cell of a `notebook` worksheet at `worksheet_idx` at the provided `index` with `value`.
  Returns the updated notebook.
  """
  def update_cell(notebook, id, updates) do
    {worksheet_idx, index} = cell_path(notebook, id)
    worksheet = Enum.at(notebook.worksheets, worksheet_idx)

    %{
      notebook
      | worksheets:
          List.replace_at(
            notebook.worksheets,
            worksheet_idx,
            %{
              worksheet
              | cells:
                  List.replace_at(
                    worksheet.cells,
                    index,
                    Map.merge(cell(notebook, worksheet_idx, index), updates)
                  )
            }
          )
    }
  end

  defp renumber_code_cells(list, idx \\ 0)

  defp renumber_code_cells([first = %{cell_type: "code"} | rest], idx) do
    [%{first | prompt_number: idx} | renumber_code_cells(rest, idx + 1)]
  end

  defp renumber_code_cells([first | rest], idx) do
    [first | renumber_code_cells(rest, idx)]
  end

  defp renumber_code_cells([], _) do
    []
  end

  defp default_content("code") do
  end

  defp default_content("markdown") do
    "# Header\ncontent"
  end

  defp cell(notebook, worksheet, index) do
    Enum.at(notebook.worksheets, worksheet).cells |> Enum.at(index)
  end

  defp cell_path(notebook, id) do
    Enum.find_value(Enum.with_index(notebook.worksheets), fn {w, wi} ->
      ci = Enum.find_index(w.cells, &(&1.id == id))
      if ci != -1, do: {wi, ci}
    end)
  end
end
