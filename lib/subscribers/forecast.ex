defmodule Forecast do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    port = 8683
    topic = "forecast"

    {:ok, subscriber_socket} = :gen_udp.open(port, [:binary, {:active, false}])

    {:ok, subscriber_pid} = GenServer.start_link(Subscriber, [])

    recv_subscriber_pid = spawn_link(__MODULE__, :recv_from_subscription, [subscriber_socket])

    GenServer.cast(subscriber_pid, {:subscribe, [topic, port, recv_subscriber_pid]})

    {:ok, init_arg}
  end

  def recv_from_subscription(subscriber_socket) do
    recv = :gen_udp.recv(subscriber_socket, 0)
    json = get_recv_data(recv)
    map = Jason.decode!(json)

    frc = forecast(map)
    publish_frc(frc, map, "aggregator")

    recv_from_subscription(subscriber_socket)
  end

  defp publish_frc(frc, data, topic) do
    publisher_pid = :global.whereis_name('publisher_pid')

    GenServer.cast(publisher_pid, {:publish, [%{"forecast" => frc, "data" => data}, topic]})
  end

  defp forecast(data) do
    cond do
      data["temperature_sensor"] < -2 && data["light_sensor"] < 128 && data["atmo_pressure_sensor"] < 720
        -> "SNOW"
      data["temperature_sensor"] < -2 && data["light_sensor"] > 128 && data["atmo_pressure_sensor"] < 680
        -> "WET_SNOW"
      data["temperature_sensor"] < -8
        -> "SNOW"
      data["temperature_sensor"] < -15 && data["wind_speed_sensor"] > 45
        -> "BLIZZARD"
      data["temperature_sensor"] > 0 && data["atmo_pressure_sensor"] < 710 && data["humidity_sensor"] > 70
                                    && data["wind_speed_sensor"] < 20
        -> "SLIGHT_RAIN"
      data["temperature_sensor"] > 0 && data["atmo_pressure_sensor"] < 690 && data["humidity_sensor"] > 70
                                    && data["wind_speed_sensor"] > 20
        -> "HEAVY_RAIN"
      data["temperature_sensor"] > 30 && data["atmo_pressure_sensor"] < 770 && data["humidity_sensor"] > 80
                                    && data["light_sensor"] > 192
        -> "HOT"
      data["temperature_sensor"] > 30 && data["atmo_pressure_sensor"] < 770 && data["humidity_sensor"] > 50
                                    && data["light_sensor"] > 192 && data["wind_speed_sensor"] > 35
        -> "CONVECTION_OVEN"
      data["temperature_sensor"] > 25 && data["atmo_pressure_sensor"] < 750 && data["humidity_sensor"] > 70
                                    && data["light_sensor"] < 192 && data["wind_speed_sensor"] < 10
        -> "CONVECTION_OVEN"
      data["temperature_sensor"] > 25 && data["atmo_pressure_sensor"] < 750 && data["humidity_sensor"] > 70
                                    && data["light_sensor"] < 192 && data["wind_speed_sensor"] > 10
        -> "SLIGHT_BREEZE"
      data["light_sensor"] < 128
        -> "CLOUDY"
      data["temperature_sensor"] > 30 && data["atmo_pressure_sensor"] < 660 && data["humidity_sensor"] > 85
                                    && data["wind_speed_sensor"] > 45
        -> "MONSOON"
      true
        -> "JUST_A_NORMAL_DAY"
    end
  end

  defp get_recv_data(recv) do
    recv = Tuple.to_list(recv)
    recv = List.last(recv)
    recv = Tuple.to_list(recv)
    str = List.last(recv)
    str
  end

end
