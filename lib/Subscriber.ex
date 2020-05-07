defmodule Subscriber do
  use GenServer

  def start_link() do
    {:ok, subscriber_socket} = :gen_udp.open(0, [:binary, {:active, false}])

    {:ok, subscriber_socket}
  end

  @impl true
  def init(_init_arg) do

    # state = %{:subscriber_socket => subscriber_socket}
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:subscribed, []}, state) do
    subscriber_socket = state[:subscriber_socket]
    recv = :gen_udp.recv(subscriber_socket, 0)
    IO.puts "Received from subscription #{recv}"
    {:noreply, state}
  end

  end
