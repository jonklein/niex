defmodule Niex.Notebook do
  @moduledoc """
  Interface to the Notebook data.  Generally not used directly - instead, use the
  functions in Niex.State to manipute the full app state including the notebook.
  """

  defstruct(
    worksheets: [%{cells: []}],
    metadata: %{name: "", version: "1.0"}
  )

  def default_title do
    "Untitled Notebook"
  end

  @doc """
  Updates the notebook metadata which contains `name` and `version` strings.
  """
  def update_metadata(notebook, metadata) do
    %{notebook | metadata: metadata}
  end

  def add_cell(notebook, worksheet_idx, idx, cell_type) do
    worksheet = Enum.at(notebook.worksheets, worksheet_idx)

    cells =
      List.insert_at(worksheet[:cells], idx, %{
        prompt_number: 0,
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
  def execute_cell(notebook, id, bindings) do
    {worksheet, index} = cell_path(notebook, id)

    cell = cell(notebook, worksheet, index)
    cmd = Enum.join(cell[:content], "\n")

    {output, bindings} =
      try do
        # currently not using stdout - may capture & display in the future
        {result, _} = Niex.Eval.capture_output(self(), cell.id, cmd, bindings)

        result
      rescue
        err ->
          {err, bindings}
      end

    {update_cell(notebook, id, %{running: true}), bindings}
  end

  @doc """
  Replaces the cell of a `notebook` worksheet at `worksheet_idx` at the provided `index` with `value`.
  Returns the updated notebook.
  """
  def update_cell(notebook, id, updates) do
    {worksheet_idx, index} = cell_path(notebook, id)
    worksheet = Enum.at(notebook.worksheets, worksheet_idx)
    index = Enum.find_index(worksheet.cells, fn c -> c.id == id end)

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

  defp cell_path(notebook, id) do
    worksheet =
      Enum.find_index(notebook.worksheets, fn w -> Enum.find(w.cells, fn c -> c.id == id end) end)

    index = Enum.find_index(Enum.at(notebook.worksheets, worksheet).cells, fn c -> c.id == id end)

    {worksheet, index}
  end
end
