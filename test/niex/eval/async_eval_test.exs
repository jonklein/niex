defmodule EvalTestServer do
  # A simple test GenServer to capture the various forms of async output for our evaluator.
  # In the actual app, this role is played by the LiveView process which receives the
  # messages and updates the application state.

  use GenServer

  def start_link(bindings, env) do
    GenServer.start_link(__MODULE__, %{env: env, bindings: bindings, output: nil})
  end

  def state(pid) do
    GenServer.call(pid, :get)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(_, _, state) do
    {:reply, state, state}
  end

  def handle_info({:command_env, env}, state) do
    {:noreply, %{state | env: env}}
  end

  def handle_info({:command_bindings, bindings}, state) do
    {:noreply, %{state | bindings: bindings}}
  end

  def handle_info({:command_output, _, output}, state) do
    {:noreply, %{state | output: output}}
  end
end

defmodule Niex.Eval.AsyncEvalTest do
  use Niex.DataCase

  def exec_sync(cmd, bindings, env) do
    #

    {:ok, capture_pid} = EvalTestServer.start_link(bindings, env)
    {:ok, eval} = Niex.Eval.AsyncEval.eval_string(capture_pid, "", cmd, bindings, env)
    Process.monitor(eval)

    receive do
      {:DOWN, _, :process, _, _} -> nil
    end

    EvalTestServer.state(capture_pid)
  end

  test "should evaluate" do
    state = exec_sync("1+1", [], [])

    assert(state.output == %{outputs: [%{text: ["2"], type: "code"}], running: false})
  end

  test "should capture and use bindings" do
    # bind, then use in next command

    state = exec_sync("x = 1+1", [], [])

    assert(state.bindings == [x: 2])

    state = exec_sync("x = x + 1", state.bindings, state.env)

    assert(state.output == %{outputs: [%{text: ["3"], type: "code"}], running: false})
  end

  test "should capture and use environment" do
    # import, then use in next command

    state = exec_sync("import Enum", [], [])
    state = exec_sync("map([1,2,3], fn i -> i * 3 end)", state.bindings, state.env)

    assert(state.output == %{outputs: [%{text: ["[3, 6, 9]"], type: "code"}], running: false})
  end

  test "should capture and use bindings after an error" do
    # Set a binding, trigger an exception, reuse the binding
    state = exec_sync("x = 2", [], [])
    state = exec_sync("y + 2", state.bindings, state.env)
    state = exec_sync("x + 2", state.bindings, state.env)

    assert(state.output == %{outputs: [%{text: ["4"], type: "code"}], running: false})
  end
end
