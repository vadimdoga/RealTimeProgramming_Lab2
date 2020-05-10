defmodule Fetch do
  use GenServer

    # PORTS:
    # 8679 - Message Broker
    # 8680 - Publisher
    # 8681 - Join Subscriber
    # 8682 - Notify subscribers
    # 8683 - Forecast Subscriber
    # 8684 - Aggregator Subscriber

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(url_legacy_sensors, url_iot, url_sensors) do
    spawn_link(__MODULE__, :start_application, [url_legacy_sensors, url_iot, url_sensors])
    {:ok, self()}
  end

  def start_application(url_legacy_sensors, url_iot, url_sensors) do
    {:ok, publisher_socket} = :gen_udp.open(8680)
    {:ok, notify_socket} = :gen_udp.open(8682)

    {:ok, subscription_manager} = SubscriptionManager.start
    :global.register_name('subscription_manager', subscription_manager)


    {:ok, _pid} = EventsourceEx.new(url_legacy_sensors, stream_to: self())
    {:ok, _pid} = EventsourceEx.new(url_iot, stream_to: self())
    {:ok, _pid} = EventsourceEx.new(url_sensors, stream_to: self())
    #generate pids for actors
    {:ok, router_pid} = GenServer.start_link(Router, [])
    {:ok, flow_router_pid} = GenServer.start_link(FlowRouter, [])
    # {:ok, aggregator_pid} = GenServer.start_link(Aggregator, [])
    aggregator_pid = ""
    {:ok, flow_aggr_pid} = GenServer.start_link(FlowAggr, [])
    {:ok, publisher_pid} = GenServer.start_link(Publisher, [])

    :global.register_name('publisher_pid', publisher_pid)


    ets_create_insert(router_pid, flow_router_pid, aggregator_pid, flow_aggr_pid, publisher_socket, notify_socket)
    recv()
  end
  #create global variables with pids
  defp ets_create_insert(router_pid, flow_router_pid, aggregator_pid, flow_aggr_pid, publisher_socket, notify_socket) do
    :ets.new(:buckets_registry, [:named_table])

    :ets.insert(:buckets_registry, {"router_pid", router_pid})
    :ets.insert(:buckets_registry, {"flow_router_pid", flow_router_pid})
    :ets.insert(:buckets_registry, {"aggregator_pid", aggregator_pid})
    :ets.insert(:buckets_registry, {"flow_aggr_pid", flow_aggr_pid})
    :ets.insert(:buckets_registry, {"publisher_socket", publisher_socket})
    :ets.insert(:buckets_registry, {"notify_socket", notify_socket})
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
