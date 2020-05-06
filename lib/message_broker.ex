defmodule MessageBroker do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    {:ok, socket} = :gen_udp.open(8679, [:binary, {:active, false}])

    main(socket)
    {:ok, init_arg}
  end

  defp main(socket) do
    #recv all messages
    recv = :gen_udp.recv(socket, 0)
    str = get_recv_data(recv)
    _map = string_to_map(str)

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

  @impl true
  def handle_cast({:name, _args}, state) do


    {:noreply, state}
  end
end
