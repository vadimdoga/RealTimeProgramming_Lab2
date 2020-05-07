defmodule Subscriber do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{})

    IO.inspect(self())
    {:ok, self()}
  end

  @impl true
  def init(_init_arg) do
    port = 8681
    {:ok, subscriber_socket} = :gen_udp.open(port, [:binary, {:active, false}])

    {:ok, %{:subscriber_socket => subscriber_socket, :subscriber_port => port}}
  end

  # def unsubscribe(address) do
  #   subscription_manager = :global.whereis_name('subscription_manager')

  #   SubscriptionManager.delete(subscription_manager, address)
  # end

  @impl true
  def handle_cast({:subscribe, topic}, state) do

    subscriber_port = state[:subscriber_port]
    subscriber_socket = state[:subscriber_socket]
    subscription_manager = :global.whereis_name('subscription_manager')
    SubscriptionManager.put(subscription_manager, subscriber_port, topic)
    IO.puts "Address subscribed succesfull on topic -  #{topic}"

    spawn(__MODULE__, :recv_from_subscription, [subscriber_socket, topic])

    {:noreply, state}
  end

  def recv_from_subscription(subscriber_socket, topic) do
    recv = :gen_udp.recv(subscriber_socket, 0)
    IO.puts "Received from topic - #{topic}"
    IO.inspect recv
    #loop
    recv_from_subscription(subscriber_socket, topic)
  end

end
