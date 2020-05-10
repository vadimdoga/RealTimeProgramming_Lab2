defmodule JoinSensors do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    port = 8681
    topic = "join"
    list_iot = []
    list_sensors = []
    list_legacy_sensors = []

    {:ok, subscriber_socket} = :gen_udp.open(port, [:binary, {:active, false}])

    {:ok, subscriber_pid} = GenServer.start_link(Subscriber, [])

    recv_subscriber_pid = spawn_link(__MODULE__, :recv_from_subscription, [subscriber_socket, list_iot, list_sensors, list_legacy_sensors])

    GenServer.cast(subscriber_pid, {:subscribe, [topic, port, recv_subscriber_pid]})

    {:ok, init_arg}
  end

  def recv_from_subscription(subscriber_socket, list_iot, list_sensors, list_legacy_sensors) do
    joined_list = []

    recv = :gen_udp.recv(subscriber_socket, 0)
    json = get_recv_data(recv)
    map = Jason.decode!(json)

    topic = classify_map(map)
    {list_iot, list_sensors, list_legacy_sensors} = add_to_list(list_iot, list_sensors, list_legacy_sensors, topic, map)

    {joined_list, list_iot, list_legacy_sensors, list_sensors} = if Enum.count(list_iot) > 1 do
      join_sensors(joined_list, list_iot, list_legacy_sensors, list_sensors)
    else
      {joined_list, list_iot, list_legacy_sensors, list_sensors}
    end
    if joined_list != [] do
      publish_list(joined_list)
    end

    recv_from_subscription(subscriber_socket, list_iot, list_sensors, list_legacy_sensors)
  end

  defp publish_list(joined_list) do
    topic = "forecast"
    publisher_pid = :global.whereis_name('publisher_pid')

    Enum.map(joined_list, fn joined_map ->
      GenServer.cast(publisher_pid, {:publish, [joined_map, topic]})
    end)
  end

  defp add_to_list(list_iot, list_sensors, list_legacy_sensors, topic, map) do
    list_iot = if topic == "iot" do
      [map | list_iot]
    else
      list_iot
    end

    list_sensors = if topic == "sensors" do
      [map | list_sensors]
    else
      list_sensors
    end

    list_legacy_sensors = if topic == "legacy_sensors" do
      [map | list_legacy_sensors]
    else
      list_legacy_sensors
    end

    {list_iot, list_sensors, list_legacy_sensors}
  end

  defp join_sensors(joined_list, list_iot, list_legacy_sensors, list_sensors) do
    joined_list = Enum.map(list_iot, fn iot_msg ->
      iot_timestamp = iot_msg["unix_timestamp_100us"]

      sensors_msg = Enum.find(list_sensors, fn sensors_msg ->
        sensors_timestamp = sensors_msg["unix_timestamp_100us"]
        (iot_timestamp - sensors_timestamp <= 100) &&
        (iot_timestamp - sensors_timestamp >= -100)
      end)

      legacy_sensors_msg = Enum.find(list_legacy_sensors, fn legacy_sensors_msg ->
        legacy_sensors_timestamp = legacy_sensors_msg["unix_timestamp_100us"]
        (iot_timestamp - legacy_sensors_timestamp <= 100) &&
        (iot_timestamp - legacy_sensors_timestamp >= -100)
      end)

      if sensors_msg != nil && legacy_sensors_msg != nil do
        %{
          "atmo_pressure_sensor" => iot_msg["atmo_pressure_sensor"],
          "wind_speed_sensor" => iot_msg["wind_speed_sensor"],
          "humidity_sensor" => legacy_sensors_msg["humidity_sensor"],
          "temperature_sensor" => legacy_sensors_msg["temperature_sensor"],
          "light_sensor" => sensors_msg["light_sensor"],
          "unix_timestamp_100us" => iot_msg["unix_timestamp_100us"]
        }
      end
    end)

    #filter the nils
    joined_list = Enum.filter(joined_list, fn x ->
      if x != nil do
        x
      end
    end)

    {joined_list, [], [], []}
  end

  defp classify_map(map) do
    check_iot = Map.has_key?(map, "atmo_pressure_sensor")
    check_legacy_sensors = Map.has_key?(map, "humidity_sensor")
    check_sensors = Map.has_key?(map, "light_sensor")

    topic = cond do
      check_iot == true -> "iot"
      check_legacy_sensors == true -> "legacy_sensors"
      check_sensors == true -> "sensors"
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
