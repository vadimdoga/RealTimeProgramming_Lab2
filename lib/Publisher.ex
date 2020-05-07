defmodule Publisher do
  use GenServer

    def start do
      {:ok, subscription_manager} = SubscriptionManager.start
      :global.register_name('subscription_manager', subscription_manager)

      GenServer.start_link(__MODULE__, subscription_manager)
    end

    def init(init_arg) do
      {:ok, init_arg}
    end

    def notify(message) do
      subscription_manager = :global.whereis_name('subscription_manager')

      SubscriptionManager.get_all(subscription_manager) |>
      Enum.map(fn {_key, address} ->
        # :gen_event.notify(pid, message)
        :gen_udp.send(address, {127,0,0,1}, 8679, message)
      end)
    end

    def publish(message) do
      [{_id, broker_socket}] = :ets.lookup(:buckets_registry, "broker_socket")

        #convert map to string
      message = Map.keys(message)
      |> Enum.map(fn key -> "#{key},#{message[key]}" end)
      |> Enum.join(",")

      :gen_udp.send(broker_socket, {127,0,0,1}, 8679, message)
    end

  end
