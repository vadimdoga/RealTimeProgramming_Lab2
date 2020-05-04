defmodule FlowAggr do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    start_time = Time.utc_now()
    frc_list = []
    full_list = []
    state = %{:start_time => start_time, :frc_list => frc_list, :full_list => full_list}
    {:ok, state}
  end

  #asyncronous function for performing task during timer
  @impl true
  def handle_cast({:flow_aggr, list_weather}, state) do
    rate = System.get_env("RATE")
    rate = String.to_integer(rate)

    frc = List.first(list_weather)
    start_time = state[:start_time]
    full_list = state[:full_list]
    frc_list = state[:frc_list]

    full_list = full_list ++ [list_weather]
    frc_list = frc_list ++ [frc]
    time = Time.utc_now()
    diff_time = Time.diff(time, start_time, :millisecond)

    if diff_time < rate do
      state = %{:start_time => start_time, :frc_list => frc_list, :full_list => full_list}
      {:noreply, state}
    else
      frc_top = top_frc(frc_list)
      mean_metrics = mean_metrics(frc_top, full_list)
      frc_list = []
      full_list = []
      state = %{:start_time => time, :frc => frc, :frc_list => frc_list, :frc_metrics => mean_metrics, :frc_top => frc_top, :full_list => full_list}
      {:noreply, state}
    end
  end

  #function that return to aggregator final frc and metrics
  @impl true
  def handle_call(:top_frc, _from, state) do

    {:reply, {state[:frc_metrics], state[:frc_top]}, state}
  end

  defp top_frc(frc_list) do
    map = Enum.frequencies(frc_list)
    map = Enum.sort(map,  fn {_k, v}, {_k1, v1} -> v > v1 end)
    tuple = Enum.at(map, 0)
    list = Tuple.to_list(tuple)
    List.first(list)
  end

  defp mean_metrics(frc, full_list) do
    full_list_size = Enum.count(full_list)
    full_list = Enum.filter(full_list, fn list ->
      fr = List.first(list)
      fr == frc
    end)

    list = Enum.map(full_list, fn list ->
      List.last(list)
    end)

    map = Enum.reduce(list, fn x, acc ->
      Map.merge(x, acc, fn _k, v1, v2 ->
        v1 + v2
      end)
    end)

    list = Enum.map(map, fn {k, v} ->
      v = v / full_list_size
      {k, v}
    end)
    list
  end




end
