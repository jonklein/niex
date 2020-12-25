defmodule Niex.AsyncEval do
  @moduledoc """
  Defines a process for asynchronous code execution and output capture.
  """

  @doc """
  Starts a process to asynchronously execute `Code.eval_string/2` with the
  provide `cmd` and `bindings`.  Sends the command output, command stdout,
  and any calls to `Niex.render/1` to the provided `output_pid` with the
  provided `context_data` (which is a cell ID string in standard Niex usage).
  Uses `Niex.AsyncOutputCapture` as the process group leader in order to
  capture the outputs.
  """
  def eval_string(output_pid, context_data, cmd, bindings) do
    # Stop any existing process for the same context data (cell)
    cleanup(context_data, Registry.lookup(Niex.CellEvaluation, context_data))
    Task.start(__MODULE__, :eval_and_capture, [output_pid, context_data, cmd, bindings])
  end

  defp cleanup(_, []) do
  end

  defp cleanup(context_data, [{pid, _}]) do
    Registry.unregister(Niex.CellEvaluation, context_data)
    Process.exit(pid, :kill)
  end

  @doc false
  def eval_and_capture(output_pid, context_data, cmd, bindings) do
    Registry.register(Niex.CellEvaluation, context_data, self())

    capture_task = Niex.AsyncOutputCapture.start_link(output_pid, context_data)

    # Set the group leader so we send stdout and other output to capture_task
    Process.group_leader(self(), capture_task.pid)

    {status, {result, bindings}} =
      try do
        {:ok, Code.eval_string(cmd, bindings)}
      rescue
        err ->
          {:error, {err, []}}
      end

    # To avoid a race condition with output messages being delivered from
    # the captutre_task, we send a :finish message and wait for the reply
    # before sending our own final output message.

    send(capture_task.pid, {:finish, self()})

    receive do
      {:finished} ->
        nil
    end

    send(
      output_pid,
      {:command_output, context_data,
       %{running: false, outputs: Niex.AsyncOutputCapture.outputs(result)}}
    )

    send(output_pid, {:command_bindings, bindings})

    Registry.unregister(Niex.CellEvaluation, context_data)

    {status, result}
  end
end
