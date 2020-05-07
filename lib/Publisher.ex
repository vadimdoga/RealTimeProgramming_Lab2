defmodule Publisher do
  use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, %{})
      {:ok, self()}
    end

    @impl true
    def init(init_arg) do

      {:ok, init_arg}
    end

    def notify(message, topic) do
      subscription_manager = :global.whereis_name('subscription_manager')
      [{_id, notify_socket}] = :ets.lookup(:buckets_registry, "notify_socket")


      SubscriptionManager.get_all(subscription_manager) |>
      Enum.map(fn {key, value} ->
        if value == String.to_atom(topic) do
          :gen_udp.send(notify_socket, {127,0,0,1}, key , message)
        end
      end)
    end

    @impl true
    def handle_cast({:publish, [message, topic]}, state) do
      [{_id, publisher_socket}] = :ets.lookup(:buckets_registry, "publisher_socket")

      #add topic to map
      message = Map.put(message, :topic, topic)

      #convert map to string
      message = Map.keys(message)
      |> Enum.map(fn key -> "#{key},#{message[key]}" end)
      |> Enum.join(",")

      :gen_udp.send(publisher_socket, {127,0,0,1}, 8679, message)

      {:noreply, state}
    end

  end
