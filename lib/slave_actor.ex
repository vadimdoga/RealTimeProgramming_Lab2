import SweetXml
defmodule Slave do
  use GenServer
  @registry :workers_registry

  def start_link(name, msg) do
    GenServer.start_link(__MODULE__, msg, name: via_tuple(name))
  end

  #Callbacks
  @impl true
  def init(msg) do
    perform_calc(msg)

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:rtl, msg}, state) do
    try do
      perform_calc(msg)
    rescue
      _ -> :ok
    end
    {:noreply, state}
  end

  @impl true
  def handle_cast({:udp_send, data}, state) do
    socket = :global.whereis_name('socket')

    #add it's topic to each map
    data = classify_map(data)
    #publish data to msg broker
    Publisher.start()
    Publisher.publish(data)

    {:noreply, state}
  end

  # defp publish(data, socket) do
  #   #convert map to string
  #   data = Map.keys(data)
  #   |> Enum.map(fn key -> "#{key},#{data[key]}" end)
  #   |> Enum.join(",")

  #   :gen_udp.send(socket, {127,0,0,1}, 8679, data)
  # end

  defp classify_map(map) do
    check_iot = Map.has_key?(map, :atmo_pressure_sensor)
    check_legacy_sensors = Map.has_key?(map, :humidity_sensor)
    check_sensors = Map.has_key?(map, :light_sensor)

    map = cond do
      check_iot == true -> Map.put(map, :topic, "iot")
      check_legacy_sensors == true -> Map.put(map, :topic, "legacy_sensors")
      check_sensors == true -> Map.put(map, :topic, "sensors")
    end
    map
  end

  ## Private
  defp perform_calc(msg) do
    data = json_parse(msg)
    isJson = is_map(data)
    parsed_data = if isJson do
      data
    else
      xml_parse(data)
    end
    data = calc_mean(parsed_data)
    # IO.inspect data
    GenServer.cast(self(), {:udp_send, data})
    # IO.inspect(self())
  end

  defp via_tuple(name) do
    {:via, Registry, {@registry, name}}
  end

  defp json_parse(msg) do
    msg_data = Jason.decode!(msg.data)
    msg_data["message"]
  end

  defp xml_parse(data) do
    unix_timestamp_100us = get_xml_timestamp(data)
    humidity_sensor_values = data |> xpath(~x"//humidity_percent/value"l, value: ~x"text()") |> Enum.map(fn %{value: value} ->
      value
    end)
    temperature_sensor_values = data |> xpath(~x"//temperature_celsius/value"l, value: ~x"text()") |> Enum.map(fn %{value: value} ->
      value
    end)

    map = %{}
    map = Map.put(map, "humidity_sensor_1", single_quotes_to_float(List.first(humidity_sensor_values)))
    map = Map.put(map, "humidity_sensor_2", single_quotes_to_float(List.last(humidity_sensor_values)))
    map = Map.put(map, "temperature_sensor_1", single_quotes_to_float(List.first(temperature_sensor_values)))
    map = Map.put(map, "temperature_sensor_2", single_quotes_to_float(List.last(temperature_sensor_values)))
    map = Map.put(map, "unix_timestamp_100us", single_quotes_to_integer(unix_timestamp_100us))
    map
  end

  defp get_xml_timestamp(xml) do
    xml = parse(xml) |> xmlElement()
    xml = Enum.at(xml, 6)
    xml = Tuple.to_list(xml)
    xml = List.last(xml)
    xml = List.first(xml)
    xml = Tuple.to_list(xml)
    xml = Enum.at(xml, 8)
    xml
  end

  defp single_quotes_to_float(num) do
    num = to_string(num)
    num = String.to_float(num)
    num
  end

  defp single_quotes_to_integer(num) do
    num = to_string(num)
    num = String.to_integer(num)
    num
  end

  defp calc_mean(data) do
    map = %{}

    timestamp = data["unix_timestamp_100us"]

    filtered_data = Enum.filter(data, fn el_tuple ->
      el_list = Tuple.to_list(el_tuple)
      el_key = List.first(el_list)
      el_last_key = String.at(el_key, -1)
      el_last_key == "1" || el_last_key == "2"
    end)

    list_size = Enum.count(filtered_data)
    final_map = if(list_size == 4) do
      first_list = [Enum.at(filtered_data, 0), Enum.at(filtered_data, 1)]
      second_list = [Enum.at(filtered_data, 2), Enum.at(filtered_data, 3)]

      map = Enum.reduce(first_list, fn x, acc ->
        mean_values(map, x, acc)
      end)
      map = Enum.reduce(second_list, fn x, acc ->
        mean_values(map, x, acc)
      end)
      map
    else
      if(list_size == 2) do
        Enum.reduce(filtered_data, fn x, acc ->
          mean_values(map, x, acc)
        end)
      end
    end

    final_map = Map.put(final_map, :unix_timestamp_100us, timestamp)
    final_map
  end

  defp mean_values(map, x, acc) do
    curr_value = Tuple.to_list(x)
    prev_value = Tuple.to_list(acc)
    v1 = List.last(curr_value)
    v2 = List.last(prev_value)
    k1 = List.first(curr_value)
    key = String.slice(k1, 0..-3)
    Map.put(map, String.to_atom(key), mean(v1, v2))
  end

  defp mean(a, b) do
    a + b / 2
  end

end

