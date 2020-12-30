defmodule NiexWeb.PageLive do
  @moduledoc false

  use NiexWeb, :live_view
  require Logger

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

  def handle_info({:command_env, env}, socket) do
    state =
      socket.assigns[:state]
      |> Niex.State.update_env(env)

    {:noreply, assign(socket, state: state)}
  end

  def handle_info({:command_stdout, _cell_id, stdout}, socket) do
    # Not currently capturing stdout content
    IO.inspect(stdout)
    {:noreply, socket}
  end

  def handle_info({:command_output, cell_id, content}, socket) do
    state =
      socket.assigns[:state]
      |> Niex.State.update_cell(cell_id, content)

    {:noreply, assign(socket, state: state)}
  end

  def handle_info({:command_bindings, bindings}, socket) do
    state =
      socket.assigns[:state]
      |> Niex.State.update_bindings(bindings)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("focus-cell", %{"ref" => id}, socket) do
    state = socket.assigns[:state] |> Niex.State.set_selected_cell(id)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("execute-cell", %{"ref" => id}, socket) do
    state =
      socket.assigns[:state]
      |> Niex.State.execute_cell(id, self())

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("blur-cell", _, socket) do
    state = socket.assigns[:state] |> Niex.State.set_selected_cell(nil)
    {:noreply, assign(socket, state: state)}
  end

  def handle_event(
        "update-content",
        %{"ref" => id, "text" => value},
        socket
      ) do
    state =
      socket.assigns[:state]
      |> Niex.State.update_cell(id, %{content: [value]})

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("add-cell", %{"type" => type, "index" => index}, socket) do
    {idx, _} = Integer.parse(index)
    {:noreply, assign(socket, state: Niex.State.add_cell(socket.assigns[:state], idx, type))}
  end

  def handle_event("remove-cell", %{"ref" => id}, socket) do
    {:noreply, assign(socket, state: Niex.State.remove_cell(socket.assigns[:state], id))}
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

  def handle_event(other, params, socket) do
    Logger.debug("Unhandled event: #{other} - #{inspect(params)}")
    {:noreply, socket}
  end
end
