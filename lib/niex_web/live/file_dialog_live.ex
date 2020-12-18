defmodule NiexWeb.FileDialogLive do
  use NiexWeb, :live_view

  def mount(_params, session, socket) do
    wd = File.cwd!()

    {
      :ok,
      assign(
        socket,
        selected: nil,
        working_directory: wd,
        title: session["title"],
        mode: session["mode"],
        reply: session["reply"],
        extensions: session["extensions"],
        paths: link_path(wd),
        filename: "Untitled",
        file_exists: false,
        files: files(socket, wd, session["mode"], session["extensions"])
      )
    }
  end

  def handle_event("cancel", %{}, socket) do
    reply = String.to_atom(socket.assigns[:reply])
    send(socket.parent_pid, {reply, nil})
    {:noreply, assign(socket, show_file_dialog: false)}
  end

  def handle_event("open", %{}, socket) do
    reply = String.to_atom(socket.assigns[:reply])
    send(socket.parent_pid, {reply, socket.assigns[:selected]})
    {:noreply, assign(socket, show_file_dialog: false)}
  end

  def handle_event("save", %{}, socket) do
    reply = String.to_atom(socket.assigns[:reply])

    send(
      socket.parent_pid,
      {reply, save_path(socket)}
    )

    {:noreply, assign(socket, show_file_dialog: false)}
  end

  def handle_event("update-filename", %{"filename" => filename}, socket) do
    socket = assign(socket, filename: filename)

    {:noreply, assign(socket, file_exists: exists?(save_path(socket)))}
  end

  def exists?(path) do
    {result, _} = File.stat(path)
    result == :ok
  end

  def handle_event("select", %{"path" => path}, socket) do
    path = Jason.decode!(path)
    {:ok, stat} = File.stat(path)
    select_path(stat.type, path, socket)
  end

  def select_path(:directory, path, socket) do
    {
      :noreply,
      assign(
        socket,
        selected: nil,
        working_directory: path,
        paths: link_path(path),
        files: files(socket, path, socket.assigns[:mode], socket.assigns[:extensions])
      )
    }
  end

  def select_path(:regular, path, socket) do
    socket = assign(socket, selected: path)

    {
      :noreply,
      assign(
        socket,
        files:
          files(
            socket,
            socket.assigns[:working_directory],
            socket.assigns[:mode],
            socket.assigns[:extensions]
          )
      )
    }
  end

  def files(socket, path, mode, extensions) do
    files =
      File.ls!(path)
      |> Enum.sort()
      |> Enum.map(fn file ->
        filepath = Path.join(path, file)
        {result, stat} = File.stat(filepath)

        if result == :ok do
          selectable =
            stat.type == :directory ||
              (mode == "open" && Enum.find(extensions, &(&1 == Path.extname(file))))

          {file, Jason.encode!(filepath), selectable, filepath == socket.assigns[:selected]}
        end
      end)
      |> Enum.filter(&(&1 != nil))
  end

  def handle_event(other, params, socket) do
    IO.inspect(other)
    IO.inspect(params)
    {:noreply, socket}
  end

  defp link_path(wd) do
    components_with_paths(Path.split(wd), Enum.at(Path.split(wd), 0), separator)
  end

  defp components_with_paths([component | rest], root, separator) do
    dir = Path.join(root, component)
    name = if(component == separator, do: component, else: component <> separator)
    [{name, Jason.encode!(dir)} | components_with_paths(rest, dir, separator)]
  end

  defp components_with_paths([], _, _) do
    []
  end

  defp separator do
    separator = Enum.at(Path.split(File.cwd!()), 0)
  end

  defp save_path(socket) do
    Path.join(socket.assigns[:working_directory], socket.assigns[:filename])
  end
end
