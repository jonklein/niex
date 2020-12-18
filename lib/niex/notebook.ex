defmodule Niex.Notebook do
  @derive Jason.Encoder

  @moduledoc

  defstruct(
    version: "1.0",
    worksheets: [%{cells: []}],
    metadata: %{name: ""}
  )

  def default_title do
    "Untitled Notebook"
  end

  def update_metadata(notebook, metadata) do
    %{notebook | metadata: metadata}
  end

  def add_cell(notebook, worksheet_idx, idx, cell_type) do
    worksheet = Enum.at(notebook.worksheets, worksheet_idx)

    cells =
      List.insert_at(worksheet[:cells], idx, %{
        prompt_number: 0,
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

  def remove_cell(notebook, worksheet_idx, index) do
    worksheet = Enum.at(notebook.worksheets, worksheet_idx)
    cells = List.delete_at(worksheet[:cells], index)

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
  def execute_cell(notebook, worksheet, idx, bindings) do
    {output, bindings} =
      Niex.Eval.start_link(Enum.join(cell(notebook, worksheet, idx)[:content], "\n"), bindings)
      |> IO.inspect()

    {update_cell(notebook, worksheet, idx, %{outputs: outputs(output)}), bindings}
  end

  @doc """
  Replaces the cell of a `notebook` worksheet at `worksheet_idx` at the provided `index` with `value`.
  Returns the updated notebook.
  """
  def update_cell(notebook, worksheet_idx, index, updates) do
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
                    worksheet[:cells],
                    index,
                    Map.merge(cell(notebook, worksheet_idx, index), updates)
                  )
            }
          )
    }
  end

  defp renumber_code_cells(list, idx \\ 0)

  defp renumber_code_cells([first | rest], idx) do
    if first[:cell_type] == "code" do
      [%{first | prompt_number: idx} | renumber_code_cells(rest, idx + 1)]
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

  @doc """
  Returns the `notebook` cell in `worksheet` at the specified `index`
  """
  def cell(notebook, worksheet, index) do
    Enum.at(notebook.worksheets, worksheet)[:cells] |> Enum.at(index)
  end

  defp outputs(output = %Niex.Content{}) do
    [%{text: Niex.Content.render(output)}]
  end

  defp outputs(output) do
    [%{text: [inspect(output)]}]
  end
end
