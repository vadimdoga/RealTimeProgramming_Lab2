defmodule TestSubscriber do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    {:ok, subscriber_pid} = GenServer.start_link(Subscriber, [])
    GenServer.cast(subscriber_pid, {:subscribe, :iot})

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
