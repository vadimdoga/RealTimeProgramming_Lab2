defmodule MessageBroker do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    {:ok, socket} = :gen_udp.open(8679, [:binary, {:active, false}])

    spawn_link(__MODULE__, :main, [socket])

    {:ok, init_arg}
  end

  def main(socket) do
    #recv all messages
    recv = :gen_udp.recv(socket, 0)
    json = get_recv_data(recv)
    map = Jason.decode!(json)
    topic = map["topic"]
    map = Map.delete(map, "topic")

    cond do
      topic == "iot" -> Publisher.notify(map, "join")
      topic == "legacy_sensors" -> Publisher.notify(map, "join")
      topic == "sensors" -> Publisher.notify(map, "join")
      true -> Publisher.notify(map, topic)
    end

    main(socket)
  end

  defp get_recv_data(recv) do
    recv = Tuple.to_list(recv)
    recv = List.last(recv)
    recv = Tuple.to_list(recv)
    str = List.last(recv)
    str
  end
end
