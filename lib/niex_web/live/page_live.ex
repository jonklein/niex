defmodule NiexWeb.PageLive do
  use NiexWeb, :live_view

  def mount(_params, _session, socket) do
    state = Niex.State.new()
    {:ok, assign(socket, state: state, show_open_dialog: false, show_save_dialog: false)}
  end

  def handle_info({:close_open_dialog, nil}, socket) do
    {:noreply, assign(socket, show_open_dialog: false)}
  end

  def handle_info({:close_open_dialog, path}, socket) do
    state = Niex.State.from_file(path)
    {:noreply, assign(socket, show_open_dialog: false, state: state)}
  end

  def handle_info({:close_save_dialog, nil}, socket) do
    {:noreply, assign(socket, show_save_dialog: false)}
  end

  def handle_info({:close_save_dialog, path}, socket) do
    state = Niex.State.save(socket.assigns[:state], "#{path}.niex")
    {:noreply, assign(socket, show_save_dialog: false, state: state)}
  end

  def handle_event("focus-cell", %{"ref" => ref}, socket) do
    {idx, _} = Integer.parse(ref)

    state =
      socket.assigns[:state]
      |> Niex.State.set_selected_cell(idx)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("execute-cell", %{"ref" => ref}, socket) do
    {idx, _} = Integer.parse(ref)

    cell = Niex.Notebook.input_cell(socket.assigns[:state], idx)

    state =
      socket.assigns[:state]
      |> Niex.Notebook.execute_cell(socket, idx, Enum.join(cell["input"]))

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("blur-cell", data = %{"ref" => ref}, socket) do
    {idx, _} = Integer.parse(ref)

    state =
      socket.assigns[:state]
      |> Niex.State.set_selected_cell(nil)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event(
        "update-content",
        data = %{"index" => index, "text" => value, "cell_type" => "markdown"},
        socket
      ) do
    {idx, _} = Integer.parse(index)

    state =
      socket.assigns[:state]
      |> Niex.Notebook.update_cell(idx, %{"source" => [value], "cell_type" => "markdown"})
      |> IO.inspect()

    {:noreply, assign(socket, state: state)}
  end

  def handle_event(
        "update-content",
        data = %{"index" => index, "text" => value, "cell_type" => "code"},
        socket
      ) do
    {idx, _} = Integer.parse(index)

    state =
      socket.assigns[:state]
      |> Niex.Notebook.update_cell(idx, %{"input" => [value], "cell_type" => "code"})

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("add-cell", %{"type" => type}, socket) do
    IO.inspect("Adding #{type}")
    {:noreply, assign(socket, state: Niex.Notebook.add_cell(socket.assigns[:state], type))}
  end

  def handle_event("remove-cell", %{"ref" => index}, socket) do
    {idx, _} = Integer.parse(index)
    {:noreply, assign(socket, state: Niex.Notebook.remove_cell(socket.assigns[:state]))}
  end

  def handle_event("open", %{}, socket) do
    {:noreply, assign(socket, show_open_dialog: true)}
  end

  def handle_event("save", %{}, socket) do
    socket =
      if(
        socket.assigns[:state].path,
        do: assign(socket, state: Niex.State.save(socket.assigns[:state])),
        else: assign(socket, show_save_dialog: true)
      )

    {:noreply, socket}
  end

  def handle_event("update-title", %{"title" => title}, socket) do
    state = Niex.Notebook.update_metadata(socket.assigns[:state], %{"name" => title})

    {:noreply, assign(socket, state: state)}
  end

  def handle_event(event, other, socket) do
    IO.puts("Other event:")
    IO.inspect(event)
    IO.inspect(other)
    {:noreply, socket}
  end
end
