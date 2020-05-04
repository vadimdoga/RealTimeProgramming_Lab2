defmodule Aggregator do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_cast({:aggregator, flow_aggr_pid}, state) do
    #call flow_aggr_actor for frc and metrics
    {frc_metrics, frc} = GenServer.call(flow_aggr_pid, :top_frc)
    if frc != nil do
      print_frc(frc, frc_metrics)
    end
    {:noreply, state}
  end
  #pretty printing
  defp print_frc(frc, frc_metrics) do
    IO.puts("|.......................................|")
    IO.puts("             FORECAST DATA:")
    IO.puts("----------------------------------------")
    IO.inspect(frc, label: "Forecast")
    IO.puts("----------------------------------------")
    IO.puts("              Metrics:")
    Enum.map(frc_metrics, fn {k,v} ->
      IO.inspect(v, label: k)
    end)
  end

end




