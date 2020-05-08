defmodule JoinSensors do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(init_arg) do
    port = 8681
    topic = :join
    index = 0
    list = []

    {:ok, subscriber_socket} = :gen_udp.open(port, [:binary, {:active, false}])

    {:ok, subscriber_pid} = GenServer.start_link(Subscriber, [])

    recv_subscriber_pid = spawn_link(__MODULE__, :recv_from_subscription, [subscriber_socket, topic, index, list])

    GenServer.cast(subscriber_pid, {:subscribe, [topic, port, recv_subscriber_pid]})

    {:ok, init_arg}
  end

  def recv_from_subscription(subscriber_socket, topic, index, list) do
    recv = :gen_udp.recv(subscriber_socket, 0)
    recv = get_recv_data(recv)
    map = convert_string_to_map(recv)
    # IO.puts "Received from topic - #{topic}"
    # IO.inspect map
    list = [map | list]
    index = index + 1
    {list, index} = if index == 100 do
      join_and_publish(list)
      {[], 0}
    else
      {list, index}
    end
    recv_from_subscription(subscriber_socket, topic, index, list)
  end

  defp join_and_publish(list) do
    topic = :forecast

    timestamp_list = Enum.reduce(list, [], fn x, acc ->
      [ String.to_integer(x["unix_timestamp_100us"]) | acc]
    end)
    timestamp_list = Enum.sort(timestamp_list)
    timestamp_list = duplicates(timestamp_list)
    # IO.inspect Enum.count(timestamp_list)
    new_list = Enum.filter(timestamp_list, fn timestamp ->
      ls = Enum.filter(list, fn x ->
        if String.to_integer(x["unix_timestamp_100us"]) == timestamp do
          x
        end
      end)
      IO.inspect ls
    end)
    IO.inspect new_list


    publisher_pid = :global.whereis_name('publisher_pid')
    # GenServer.cast(publisher_pid, {:publish, [data, topic]})

    :timer.sleep(1000)
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

  defp convert_string_to_map(str) do
    str_list = String.split(str, ",")

    map = Enum.chunk_every(str_list, 2) |> Enum.map(fn [a, b] -> {a, b} end) |> Map.new
    map
  end

  defp get_recv_data(recv) do
    recv = Tuple.to_list(recv)
    recv = List.last(recv)
    recv = Tuple.to_list(recv)
    str = List.last(recv)
    str
  end

end
