defmodule Subscriber do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{})

    {:ok, self()}
  end

  @impl true
  def init(_init_arg) do

    {:ok, %{}}
  end

  # def unsubscribe(address) do
  #   subscription_manager = :global.whereis_name('subscription_manager')

  #   SubscriptionManager.delete(subscription_manager, address)
  # end

  @impl true
  def handle_cast({:unsubscribe, [port, topic]}, state) do
    subscription_manager = :global.whereis_name('subscription_manager')
    SubscriptionManager.delete(subscription_manager, port)
    recv_pid = state[:recv_pid]
    Process.exit(recv_pid, :unsubscribe)
    IO.puts "Address unsubscribed succesfull from topic -  #{topic}"

    {:noreply, state}
  end

  @impl true
  def handle_cast({:subscribe, [topic, subscriber_port, subscriber_socket]}, state) do
    subscription_manager = :global.whereis_name('subscription_manager')
    SubscriptionManager.put(subscription_manager, subscriber_port, topic)
    IO.puts "Address subscribed succesfull on topic -  #{topic}"

    recv_pid = spawn(__MODULE__, :recv_from_subscription, [subscriber_socket, topic])
    state = Map.put(state, :recv_pid, recv_pid)
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
