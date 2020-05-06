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
    IO.puts "recv"
    recv = :gen_udp.recv(socket, 0)
    IO.inspect recv
    main(socket)
  end

  @impl true
  def handle_cast({:name, _args}, state) do


    {:noreply, state}
  end
end
