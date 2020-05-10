defmodule Aggregator do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    port = 8684
    topic = "aggregator"

    {:ok, subscriber_socket} = :gen_udp.open(port, [:binary, {:active, false}])

    {:ok, subscriber_pid} = GenServer.start_link(Subscriber, [])

    recv_subscriber_pid = spawn_link(__MODULE__, :recv_from_subscription, [subscriber_socket])

    GenServer.cast(subscriber_pid, {:subscribe, [topic, port, recv_subscriber_pid]})

    {:ok, init_arg}
  end

  def recv_from_subscription(subscriber_socket) do
    recv = :gen_udp.recv(subscriber_socket, 0)
    json = get_recv_data(recv)
    map = Jason.decode!(json)
    frc = map["forecast"]
    data = map["data"]

    [{_id, flow_aggr_pid}] = :ets.lookup(:buckets_registry, "flow_aggr_pid")

    GenServer.cast(flow_aggr_pid, {:flow_aggr, [frc, data]})
    # GenServer.cast(self(), {:aggregator, flow_aggr_pid})
    spawn_link(__MODULE__, :aggregator, [flow_aggr_pid])

    recv_from_subscription(subscriber_socket)
  end

  def aggregator(flow_aggr_pid) do
    #call flow_aggr_actor for frc and metrics
    {frc_metrics, frc} = GenServer.call(flow_aggr_pid, :top_frc)
    if frc != nil do
      print_frc(frc, frc_metrics)
    end
  end

  # @impl true
  # def handle_cast({:aggregator, flow_aggr_pid}, state) do

  #   {:noreply, state}
  # end
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

  defp get_recv_data(recv) do
    recv = Tuple.to_list(recv)
    recv = List.last(recv)
    recv = Tuple.to_list(recv)
    str = List.last(recv)
    str
  end

end
