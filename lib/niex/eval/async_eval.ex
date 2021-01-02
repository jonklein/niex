defmodule Niex.Eval.AsyncEval do
  @moduledoc """
  Defines a process for asynchronous code execution and capture of various forms
  of output and state.  Along with the `Niex.Eval.OutputCapture` module, this
  module captures: 1) expression final output, 2) intermediate results via `Niex.render/1`,
  3) stdout, 4) __ENV__ manipulation, 5) global bindings.
  """

  @doc """
  Starts a process to asynchronously execute `Code.eval_string/2` with the
  provide `cmd` and `bindings`.  Sends the command output, command stdout,
  and any calls to `Niex.render/1` to the provided `output_pid` with the
  provided `context_data` (which is a cell ID string in standard Niex usage).
  Uses `Niex.Eval.OutputCapture` as the process group leader in order to
  capture the outputs.
  """
  def eval_string(output_pid, context_data, cmd, bindings, env) do
    # Stop any existing process for the same context data (cell)
    cleanup(context_data, Registry.lookup(Niex.CellEvaluation, context_data))
    Task.start(__MODULE__, :eval_and_capture, [output_pid, context_data, cmd, bindings, env])
  end

  @doc false
  def eval_and_capture(output_pid, context_data, cmd, bindings, env) do
    Registry.register(Niex.CellEvaluation, context_data, self())

    capture_task = Niex.Eval.OutputCapture.start_link(output_pid, context_data)

    # Set the group leader so we send stdout and other output to capture_task
    Process.group_leader(self(), capture_task.pid)

    {status, {result, bindings}} =
      try do
        {:ok, eval_string_with_env(output_pid, cmd, bindings, env)}
      rescue
        err ->
          # Error in user code cell.  Filter the stacktrace by removing frames
          # higher than this one (ie, Niex internals).

          trace =
            __STACKTRACE__
            |> Enum.take_while(fn {mod, _, _, _} ->
              Enum.at(String.split(Atom.to_string(mod), "."), 1) != "Niex"
            end)

          {:error,
           {Niex.Content.pre(
              Exception.format_banner(:error, err) <> Exception.format_stacktrace(trace)
            ), nil}}
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
       %{running: false, outputs: Niex.Eval.OutputCapture.outputs(result)}}
    )

    if bindings do
      send(output_pid, {:command_bindings, bindings})
    end

    Registry.unregister(Niex.CellEvaluation, context_data)

    {status, result}
  end

  defp eval_string_with_env(output_pid, string, bindings, env) do
    # In order to capture the __ENV__ from the string, we create
    # a quoted expression that combines the input string with a
    # call to send the env to the output_pid.

    {:ok, expr} = Code.string_to_quoted(string)

    Code.eval_quoted(
      quote do
        # This is the funniest line of Elixir I've written.  The expr
        # expression may have side effects in the form of __ENV__ manipulation
        # (import, require, alias, etc).  We need to evaluate expr and capture the
        # result for return, capture the __ENV__ afterwards, and then return
        # the result - and we need to do it without polluting the bindings namespace
        # with our own internal bindings.

        Enum.at(
          [unquote(expr), send(unquote(output_pid), {:command_env, __ENV__})],
          0
        )
      end,
      bindings,
      env
    )
  end

  defp cleanup(_, []) do
  end

  defp cleanup(context_data, [{pid, _}]) do
    Registry.unregister(Niex.CellEvaluation, context_data)
    Process.exit(pid, :kill)
  end
end
