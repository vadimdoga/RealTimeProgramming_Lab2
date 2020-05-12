defmodule Publisher do
  use GenServer
  require Logger

    def start_link do
      GenServer.start_link(__MODULE__, %{})
      {:ok, self()}
    end

    @impl true
    def init(_init_arg) do
      {:ok, socket} = :gen_tcp.connect('localhost', 1883, [:binary, active: false, packet: :raw])
      Logger.info("Connecting to mosquitto")
      connect(socket)

      {:ok, %{socket: socket}}
    end

    def notify(message, topic) do
      subscription_manager = :global.whereis_name('subscription_manager')
      [{_id, notify_socket}] = :ets.lookup(:buckets_registry, "notify_socket")

      message = Jason.encode!(message)

      SubscriptionManager.get_all(subscription_manager) |>
      Enum.map(fn {key, value} ->
        if value == topic do
          :gen_udp.send(notify_socket, {127,0,0,1}, key , message)
        end
      end)
    end

    @impl true
    def handle_cast({:publish, [message, topic]}, state) do
      [{_id, publisher_socket}] = :ets.lookup(:buckets_registry, "publisher_socket")

      #add topic to map
      message = Map.put(message, "topic", topic)

      message = Jason.encode!(message)

      :gen_udp.send(publisher_socket, {127,0,0,1}, 8679, message)

      {:noreply, state}
    end

    @impl true
    def handle_cast({:publish_as_packet, [message, topic]}, state) do
      socket = state.socket
      message = Jason.encode!(message)

      publish(socket, topic, message)

      {:noreply, state}
    end

    def connect(socket) do
      data_map = %{
        protocol: "MQTT",
        protocol_version: 0b00000100,
        user_name: nil,
        password: nil,
        clean_session: true,
        keep_alive: 60,
        client_id: "vadim",
        will: nil
      }

      #prepare packet for connection
      data = [
        encode(1, 0),
        variable_length_encode([
          protocol_header(data_map.protocol, data_map.protocol_version),
          connection_flags(data_map),
          keep_alive(data_map),
          payload(data_map)
          ])
      ]
      #send data for connection
      :gen_tcp.send(socket, data)
      #recv ack from connect
      {:ok, packet} = :gen_tcp.recv(socket, 0)
      <<_,_,_,return_code>> = packet
      if return_code == 0 do
        Logger.info("Connected to mosquitto. Received return code #{return_code}")
      else
        Logger.error("Connection error. Return code #{return_code}")
        exit(:error_connection)
      end
    end

    def publish(socket, topic, message) do
      #compute flags
      <<flags::4>> = <<0::1, 0::integer-size(2), 0::1>>
      #topic length
      length_prefix = <<byte_size(topic)::big-integer-size(16)>>
      data_publish = [encode(3, flags), variable_length_encode([[length_prefix, topic], message])]
      #send publish
      :gen_tcp.send(socket, data_publish)
    end

    defp variable_length_encode(data) when is_list(data) do
      length_prefix = data |> IO.iodata_length() |> remaining_length()
      length_prefix ++ data
    end

    defp encode(opcode, flags) do
      <<opcode::4, flags::4>>
    end

    defp protocol_header(protocol, version) do
      [length_encode(protocol), version]
    end

    defp length_encode(data) do
      length_prefix = <<byte_size(data)::big-integer-size(16)>>
      [length_prefix, data]
    end

    defp connection_flags(data) do
      <<
        flag(data.user_name)::integer-size(1),
        flag(data.password)::integer-size(1),
        # will retain
        flag(0)::integer-size(1),
        # will qos
        0::integer-size(2),
        # will flag
        flag(0)::integer-size(1),
        flag(data.clean_session)::integer-size(1),
        # reserved bit
        0::1
      >>
    end

    defp flag(f) when f in [0, nil, false], do: 0

    defp flag(_), do: 1

    defp keep_alive(f) do
      <<f.keep_alive::big-integer-size(16)>>
    end

    defp payload(f) do
      [f.client_id, f.user_name, f.password]
      |> Enum.filter(&is_binary/1)
      |> Enum.map(&length_encode/1)
    end

    @highbit 0b10000000
    defp remaining_length(n) when n < @highbit, do: [<<0::1, n::7>>]

    defp remaining_length(n) do
      [<<1::1, rem(n, @highbit)::7>>] ++ remaining_length(div(n, @highbit))
    end
  end
