defmodule MqttAdapter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    port = 8685
    topic = "forecast"

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

    publish(map, "test")

    recv_from_subscription(subscriber_socket)
  end

  defp publish(map, topic) do
    publisher_pid = :global.whereis_name('publisher_pid')

    GenServer.cast(publisher_pid, {:publish_as_packet, [map, topic]})

  end

  defp get_recv_data(recv) do
    recv = Tuple.to_list(recv)
    recv = List.last(recv)
    recv = Tuple.to_list(recv)
    str = List.last(recv)
    str
  end

end
