defmodule Niex.IOCapture do
  def start_link() do
    Task.async(__MODULE__, :capture, [])
  end

  def capture(io \\ "") do
    receive do
      {:io_request, pid, reply_as, {:put_chars, _, string}} ->
        # IO - capture string and listen some more
        send(pid, {:io_reply, reply_as, :ok})
        capture(io <> string)

      {:shutdown, pid} ->
        # shutdown message - send back captured io
        send(pid, {:output, io})

      _ ->
        capture(io)
    end
  end
end

defmodule Niex.Eval do
  @doc """
  A utility function to capture stdout from a function call.  Returns the
  tuple of `{result, stdout}`.  If an exception is raised in the function, it
  is re-raised here.
  """
  def capture_stdout(f) do
    result = Task.async(__MODULE__, :do_capture, [f]) |> Task.await()

    case result do
      {:ok, result, stdout} ->
        {result, stdout}

      {:error, err, stdout} ->
        raise err
    end
  end

  def do_capture(f) do
    task = Niex.IOCapture.start_link()
    Process.group_leader(self(), task.pid)

    {status, result} =
      try do
        {:ok, f.()}
      rescue
        err ->
          {:error, err}
      end

    send(task.pid, {:shutdown, self()})

    stdout =
      receive do
        {:output, o} -> o
      end

    {status, result, stdout}
  end
end
