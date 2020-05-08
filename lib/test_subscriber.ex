defmodule TestSubscriber do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    port = 8681
    topic = :iot
    {:ok, subscriber_socket} = :gen_udp.open(port, [:binary, {:active, false}])

    {:ok, subscriber_pid} = GenServer.start_link(Subscriber, [])
    GenServer.cast(subscriber_pid, {:subscribe, [topic, port, subscriber_socket]})
    :timer.sleep(10000)
    GenServer.cast(subscriber_pid, {:unsubscribe, [port, topic]})

    {:ok, init_arg}
  end

  def main(manager, subscriber) do

    main(manager, subscriber)
  end


  # @impl true
  # def handle_cast({:bla, _args}, state) do


  #   {:noreply, state}
  # end
end
