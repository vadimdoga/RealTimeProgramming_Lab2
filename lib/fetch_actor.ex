defmodule Fetch do
  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(url) do
    {:ok, _pid} = EventsourceEx.new(url, stream_to: self())
    #generate pids for actors
    {:ok, router_pid} = GenServer.start_link(Router, [])
    {:ok, flow_router_pid} = GenServer.start_link(FlowRouter, [])
    {:ok, aggregator_pid} = GenServer.start_link(Aggregator, [])
    {:ok, flow_aggr_pid} = GenServer.start_link(FlowAggr, [])

    ets_create_insert(router_pid, flow_router_pid, aggregator_pid, flow_aggr_pid)

    recv()
  end
  #create global variables with pids
  defp ets_create_insert(router_pid, flow_router_pid, aggregator_pid, flow_aggr_pid) do
    :ets.new(:buckets_registry, [:named_table])

    :ets.insert(:buckets_registry, {"router_pid", router_pid})
    :ets.insert(:buckets_registry, {"flow_router_pid", flow_router_pid})
    :ets.insert(:buckets_registry, {"aggregator_pid", aggregator_pid})
    :ets.insert(:buckets_registry, {"flow_aggr_pid", flow_aggr_pid})
  end
  #wait for msg
  defp recv do
    receive do
      msg -> msg_operations(msg)
    end

    recv()
  end

  defp msg_operations(msg) do
    #use router pid form kind of global state
    [{_id, router_pid}] = :ets.lookup(:buckets_registry, "router_pid")
    [{_id, flow_pid}] = :ets.lookup(:buckets_registry, "flow_router_pid")
    #send smth to pids
    GenServer.cast(flow_pid, :to_flow)
    GenServer.cast(router_pid, {:fetch_data, msg, flow_pid})
  end

end
