defmodule Niex.IOCapture do
  def start_link(output_pid, worksheet, id) do
    Task.async(__MODULE__, :capture, [output_pid, worksheet, id])
  end

  def capture(output_pid, worksheet, id, io \\ "") do
    receive do
      {:io_request, pid, reply_as, {:put_chars, _, string}} ->
        # IO - capture string and listen some more
        send(pid, {:io_reply, reply_as, :ok})
        capture(output_pid, worksheet, id, io <> string)

      {:render, content} ->
        send(output_pid, {:update_cell_output, worksheet, id, %{outputs: outputs(content)}})
        capture(output_pid, worksheet, id, io)

      {:shutdown, pid} ->
        # shutdown message - send back captured io
        send(pid, {:output, io})
        capture(output_pid, worksheet, id, io)

      msg ->
        IO.inspect("Unknown message: #{inspect(msg)}")
        capture(output_pid, worksheet, id, io)
    end
  end

  def outputs(output = %Niex.Content{}) do
    [%{text: Niex.Content.render(output)}]
  end

  def outputs(output) do
    [%{text: [inspect(output)]}]
  end
end

defmodule Niex.Eval do
  @doc """
  A utility function to capture stdout from a function call.  Returns the
  tuple of `{result, stdout}`.  If an exception is raised in the function, it
  is re-raised here.
  """
  def capture_output(output_pid, worksheet, id, cmd, bindings) do
    result = Task.start_link(__MODULE__, :do_capture, [output_pid, worksheet, id, cmd, bindings])

    case result do
      {:ok, result, stdout} ->
        {result, stdout}

      {:error, err, _} ->
        raise err
    end
  end

  def do_capture(output_pid, worksheet, id, cmd, bindings) do
    capture_task = Niex.IOCapture.start_link(output_pid, worksheet, id)
    Process.group_leader(self(), capture_task.pid)

    {status, {result, bindings}} =
      try do
        {:ok, Code.eval_string(cmd, bindings)}
      rescue
        err ->
          {:error, {err, []}}
      end

    send(capture_task.pid, {:shutdown, self()})

    stdout =
      receive do
        {:output, o} -> o
      end

    send(
      output_pid,
      {:update_cell_output, worksheet, id,
       %{running: false, outputs: Niex.IOCapture.outputs(result)}, bindings}
    )

    {status, result, stdout}
  end
end
