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
    str = get_recv_data(recv)
    map = convert_string_to_map(str)
    topic = map["topic"]
    map = Map.delete(map, "topic")
    str = convert_map_to_string(map)

    cond do
      topic == "iot" -> Publisher.notify(str, "join")
      topic == "legacy_sensors" -> Publisher.notify(str, "join")
      topic == "sensors" -> Publisher.notify(str, "join")
      true -> Publisher.notify(str, topic)
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

  defp convert_map_to_string(message) do
    Map.keys(message)
    |> Enum.map(fn key -> "#{key},#{message[key]}" end)
    |> Enum.join(",")
  end

  defp convert_string_to_map(str) do
    str_list = String.split(str, ",")

    map = Enum.chunk_every(str_list, 2) |> Enum.map(fn [a, b] -> {a, b} end) |> Map.new
    map
  end

end
