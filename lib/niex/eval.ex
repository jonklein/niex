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
  def start_link(cmd, bindings) do
    Task.async(__MODULE__, :run, [cmd, bindings])
    |> Task.await()
  end

  def run(cmd, bindings) do
    try do
      task = Niex.IOCapture.start_link()
      Process.group_leader(self(), task.pid)
      result = Code.eval_string(cmd, bindings)
      send(task.pid, {:shutdown, self()})

      stdout =
        receive do
          {:output, o} -> o
        end

      result
    rescue
      err ->
        {err, bindings}
    end
  end
end
