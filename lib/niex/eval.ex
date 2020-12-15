defmodule Niex.Capture do

  def start_link() do
    Task.async(__MODULE__, :capture, [])
  end

  def capture() do
    IO.puts("Capturing...")
    receive do
      {:io_request, pid, reply_as, data} ->
        IO.inspect("Got: #{inspect(data)}")
        send(pid, {:io_reply, reply_as, :ok})
        :ok

        other ->
          IO.inspect(other)
    end

    capture
  end
end

defmodule Niex.Eval do
  import Kernel, except: [alias: 1]

  def start_link(cmd, bindings) do
    Task.async(__MODULE__, :run, [cmd, bindings])
      |> Task.await
      |> IO.inspect
  end

  def run(cmd, bindings) do
    try do
      task = Niex.Capture.start_link()
      Process.group_leader(self(), task.pid)
      result = Code.eval_string(cmd, bindings, functions: [{Niex.Eval, [xalias: 1]}])
      Task.shutdown(task)

      result
    rescue
      err ->
        {err, bindings}
    end
  end

  def xalias(x) do
    x |> IO.inspect()
    123
  end

  def test(x) do
    IO.inspect(x)
  end
end
