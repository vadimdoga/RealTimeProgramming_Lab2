defmodule Subscriber do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{})

    {:ok, self()}
  end

  @impl true
  def init(_init_arg) do

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:unsubscribe, [port, topic]}, state) do
    subscription_manager = :global.whereis_name('subscription_manager')
    SubscriptionManager.delete(subscription_manager, port)
    recv_subscriber_pid = state[:recv_subscriber_pid]
    Process.exit(recv_subscriber_pid, :unsubscribe)
    Logger.info("Address unsubscribed succesfull from topic -  #{topic}")

    {:noreply, state}
  end

  @impl true
  def handle_cast({:subscribe, [topic, subscriber_port, recv_subscriber_pid]}, state) do
    subscription_manager = :global.whereis_name('subscription_manager')
    SubscriptionManager.put(subscription_manager, subscriber_port, topic)
    Logger.info("Address subscribed succesfull on topic -  #{topic}")

    state = Map.put(state, :recv_subscriber_pid, recv_subscriber_pid)
    {:noreply, state}
  end


end
