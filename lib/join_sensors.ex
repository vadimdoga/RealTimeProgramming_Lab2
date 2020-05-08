defmodule JoinSensors do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    port = 8681
    topic = :join
    list = []
    list_iot = []
    list_sensors = []
    list_legacy_sensors = []

    {:ok, subscriber_socket} = :gen_udp.open(port, [:binary, {:active, false}])

    {:ok, subscriber_pid} = GenServer.start_link(Subscriber, [])

    recv_subscriber_pid = spawn_link(__MODULE__, :recv_from_subscription, [subscriber_socket, topic, list, list_iot, list_sensors, list_legacy_sensors])

    GenServer.cast(subscriber_pid, {:subscribe, [topic, port, recv_subscriber_pid]})

    {:ok, init_arg}
  end

  def recv_from_subscription(subscriber_socket, _topic, list, list_iot, list_sensors, list_legacy_sensors) do
    recv = :gen_udp.recv(subscriber_socket, 0)
    recv = get_recv_data(recv)
    map = convert_string_to_map(recv)
    # IO.puts "Received from topic - #{topic}"
    # IO.inspect map
    topic = classify_map(map)
    {list_iot, list_sensors, list_legacy_sensors} = add_to_list(list_iot, list_sensors, list_legacy_sensors, topic, map)

    {list, list_iot, list_legacy_sensors, list_sensors} = if Enum.count(list_iot) > 1 && Enum.count(list_sensors) > 1 && Enum.count(list_legacy_sensors) > 1 do
      get_duplicates(list, list_iot, list_legacy_sensors, list_sensors)
    else
      {list, list_iot, list_legacy_sensors, list_sensors}
    end

    list_size = Enum.count(list)
    {list, list_iot, list_legacy_sensors, list_sensors} = if list_size == 100 do
      join_and_publish(list)
      {[], [], [], []}
    else
      {list, list_iot, list_legacy_sensors, list_sensors}
    end
    recv_from_subscription(subscriber_socket, topic, list, list_iot, list_sensors, list_legacy_sensors)
  end

  defp join_and_publish(_list) do
    IO.puts "Its time to send"
    # topic = :forecast

    # timestamp_list = Enum.reduce(list, [], fn x, acc ->
    #   [ String.to_integer(x["unix_timestamp_100us"]) | acc]
    # end)
    # timestamp_list = Enum.sort(timestamp_list)
    # timestamp_list = duplicates(timestamp_list)
    # # IO.inspect Enum.count(timestamp_list)
    # new_list = Enum.filter(timestamp_list, fn timestamp ->
    #   ls = Enum.filter(list, fn x ->
    #     if String.to_integer(x["unix_timestamp_100us"]) == timestamp do
    #       x
    #     end
    #   end)
    #   IO.inspect ls
    # end)
    # IO.inspect new_list


    # publisher_pid = :global.whereis_name('publisher_pid')
    # # GenServer.cast(publisher_pid, {:publish, [data, topic]})

    # :timer.sleep(1000)
  end

  defp add_to_list(list_iot, list_sensors, list_legacy_sensors, topic, map) do
    list_iot = if topic == :iot do
      [map | list_iot]
    else
      list_iot
    end

    list_sensors = if topic == :sensors do
      [map | list_sensors]
    else
      list_sensors
    end

    list_legacy_sensors = if topic == :legacy_sensors do
      [map | list_legacy_sensors]
    else
      list_legacy_sensors
    end

    {list_iot, list_sensors, list_legacy_sensors}
  end

  defp duplicates(list) do
    acc_dupes = fn(x, {elems, dupes}) ->
      case Map.has_key?(elems, x) do
        true -> {elems, Map.put(dupes, x, nil)}
        false -> {Map.put(elems, x, nil), dupes}
      end
    end

    list |> Enum.reduce({%{}, %{}}, acc_dupes) |> elem(1) |> Map.keys()
  end

  defp get_duplicates(list, list_iot, list_legacy_sensors, list_sensors) do
    #fuck


    {list, list_iot, list_legacy_sensors, list_sensors}
  end

  defp convert_string_to_map(str) do
    str_list = String.split(str, ",")

    map = Enum.chunk_every(str_list, 2) |> Enum.map(fn [a, b] -> {String.to_atom(a), b} end) |> Map.new
    map
  end

  defp classify_map(map) do
    check_iot = Map.has_key?(map, :atmo_pressure_sensor)
    check_legacy_sensors = Map.has_key?(map, :humidity_sensor)
    check_sensors = Map.has_key?(map, :light_sensor)

    topic = cond do
      check_iot == true -> :iot
      check_legacy_sensors == true -> :legacy_sensors
      check_sensors == true -> :sensors
    end
    topic
  end

  defp get_recv_data(recv) do
    recv = Tuple.to_list(recv)
    recv = List.last(recv)
    recv = Tuple.to_list(recv)
    str = List.last(recv)
    str
  end

end
