defmodule Niex.Eval.OutputCapture do
  @moduledoc """
  Asynchronously captures stdout and Niex render calls and sends them to the
  provided `output_id`.  Gets set as the group_leader for the process performing
  the evaluation.
  """

  def start_link(output_pid, context_data) do
    Task.async(__MODULE__, :capture, [output_pid, context_data])
  end

  def capture(output_pid, context_data) do
    receive do
      {:io_request, pid, reply_as, {:put_chars, _, string}} ->
        send(pid, {:io_reply, reply_as, :ok})
        send(output_pid, {:command_stdout, context_data, string})
        capture(output_pid, context_data)

      {:render, content} ->
        send(output_pid, {:command_output, context_data, %{outputs: outputs(content)}})
        capture(output_pid, context_data)

      {:finish, pid} ->
        send(pid, {:finished})

      _ ->
        # whatever, keep going
        capture(output_pid, context_data)
    end
  end

  def outputs(output = %Niex.Content{}) do
    [%{type: "html", text: Niex.Content.render(output)}]
  end

  def outputs(output) do
    [%{type: "code", text: [inspect(output)]}]
  end
end
