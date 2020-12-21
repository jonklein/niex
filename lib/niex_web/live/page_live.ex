defmodule NiexWeb.PageLive do
  use NiexWeb, :live_view

  def mount(_params, _session, socket) do
    state = Niex.State.new()

    {:ok,
     assign(socket,
       state: state,
       show_open_dialog: false,
       show_save_dialog: false,
       document_title: Niex.Notebook.default_title()
     )}
  end

  def put_temp_flash(socket, key, msg) do
    Process.send_after(self(), {:clear_flash}, 3000)
    socket |> put_flash(key, msg)
  end

  def handle_info({:clear_flash}, socket) do
    {:noreply, clear_flash(socket)}
  end

  def handle_info({:close_open_dialog, nil}, socket) do
    {:noreply, assign(socket, show_open_dialog: false)}
  end

  def handle_info({:close_open_dialog, path}, socket) do
    state = Niex.State.from_file(path)

    {:noreply,
     assign(socket,
       show_open_dialog: false,
       state: state,
       document_title: state.notebook.metadata[:name]
     )}
  end

  def handle_info({:close_save_dialog, nil}, socket) do
    {:noreply, assign(socket, show_save_dialog: false)}
  end

  def handle_info({:close_save_dialog, path}, socket) do
    state = Niex.State.save(socket.assigns[:state], path)

    socket =
      socket
      |> assign(
        show_save_dialog: false,
        state: state,
        document_title: state.notebook.metadata[:name]
      )
      |> put_temp_flash(:info, "Notebook saved!")

    {:noreply, socket}
  end

  def handle_info({:update_cell_output, worksheet, id, content}, socket) do
    idx =
      Enum.at(socket.assigns[:state].notebook.worksheets, 0).cells
      |> Enum.find_index(fn c -> c.id == id end)

    state =
      socket.assigns[:state]
      |> Niex.State.update_cell(idx, content)

    {:noreply, assign(socket, state: state)}
  end

  def handle_info({:update_cell_output, worksheet, id, content, bindings}, socket) do
    idx =
      Enum.at(socket.assigns[:state].notebook.worksheets, 0).cells
      |> Enum.find_index(fn c -> c.id == id end)

    state =
      socket.assigns[:state]
      |> Niex.State.update_cell(idx, content)
      |> Niex.State.update_bindings(bindings)

    {:noreply, assign(socket, state: state)}
  end

  def handle_info({:blur_cell_delayed}, socket) do
    state = socket.assigns[:state] |> Niex.State.set_selected_cell(nil)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("focus-cell", %{"ref" => ref}, socket) do
    {idx, _} = Integer.parse(ref)

    state = socket.assigns[:state] |> Niex.State.set_selected_cell(idx)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("execute-cell", %{"index" => index}, socket) do
    {idx, _} = Integer.parse(index)

    state =
      socket.assigns[:state]
      |> Niex.State.execute_cell(idx)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("blur-cell", _, socket) do
    # There's a race condition
    Process.send_after(self(), {:blur_cell_delayed}, 100)
    {:noreply, socket}
  end

  def handle_event(
        "update-content",
        %{"index" => index, "text" => value},
        socket
      ) do
    {idx, _} = Integer.parse(index)

    state =
      socket.assigns[:state]
      |> Niex.State.update_cell(idx, %{content: [value]})

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("add-cell", %{"type" => type, "index" => index}, socket) do
    {idx, _} = Integer.parse(index)
    {:noreply, assign(socket, state: Niex.State.add_cell(socket.assigns[:state], idx, type))}
  end

  def handle_event("remove-cell", %{"index" => index}, socket) do
    {idx, _} = Integer.parse(index)
    {:noreply, assign(socket, state: Niex.State.remove_cell(socket.assigns[:state], idx))}
  end

  def handle_event("open", %{}, socket) do
    {:noreply, assign(socket, show_open_dialog: true)}
  end

  def handle_event("save", %{}, socket) do
    socket =
      if(
        socket.assigns[:state].path,
        do:
          socket
          |> assign(state: Niex.State.save(socket.assigns[:state]))
          |> put_temp_flash(:info, "Notebook saved!"),
        else: assign(socket, show_save_dialog: true)
      )

    {:noreply, socket}
  end

  def handle_event("update-title", %{"title" => title}, socket) do
    state = Niex.State.update_metadata(socket.assigns[:state], %{name: title})
    {:noreply, assign(socket, state: state, document_title: title)}
  end

  def handle_event(other, _, socket) do
    {:noreply, socket}
  end
end
