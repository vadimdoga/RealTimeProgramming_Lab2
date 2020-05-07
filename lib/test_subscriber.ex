defmodule TestSubscriber do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    {:ok, subscriber} = Subscriber.start_link()
    SubscriptionManager.subscribe(server, name, pid)
    # manager = :global.whereis_name('manager')
    # Publisher.subscribe(manager, 'subs_node2', subscriber)


    # spawn_link(__MODULE__, :main, [manager, subscriber])

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
