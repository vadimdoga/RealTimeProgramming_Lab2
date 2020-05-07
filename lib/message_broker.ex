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
    map = string_to_map(str)
    topic = map["topic"]

    Publisher.notify(str, topic)

    # manager = :global.whereis_name('manager')
    # Publisher.notify(manager, "Hello !!")
    main(socket)
  end

  defp get_recv_data(recv) do
    recv = Tuple.to_list(recv)
    recv = List.last(recv)
    recv = Tuple.to_list(recv)
    str = List.last(recv)
    str
  end

  defp string_to_map(str) do
    str_list = String.split(str, ",")

    map = Enum.chunk_every(str_list, 2) |> Enum.map(fn [a, b] -> {a, b} end) |> Map.new
    map
  end

end
