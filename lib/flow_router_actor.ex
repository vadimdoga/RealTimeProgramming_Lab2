defmodule FlowRouter do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{list: []}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    start_time = Time.utc_now()
    index = 0
    state = %{:start_time => start_time, :index => index}
    {:ok, state}
  end

  #asyncronous function for performing task during timer
  @impl true
  def handle_cast(:to_flow, state) do
    start_time = state[:start_time]
    index = state[:index]

    time = Time.utc_now()
    diff_time = Time.diff(time, start_time, :millisecond)

    if diff_time < 1000 do
      index = index + 1
      state = %{:start_time => start_time, :index => index}
      {:noreply, state}
    else
      current_flow = index
      index = 0
      state = %{:start_time => time, :index => index, :current_flow => current_flow}
      {:noreply, state}
    end
  end

  #function that return to router nr of workers
  @impl true
  def handle_call(:workers_nr, _from, state) do

    {:reply, get_workers(state[:current_flow]), state}
  end

  #based on nr of msg per second say how much actors to use
  defp get_workers(msg_counter) do
    cond do
      msg_counter < 10 -> 1
      msg_counter > 10 && msg_counter < 30 -> 2
      msg_counter > 30 && msg_counter < 70 -> 3
      msg_counter > 80 && msg_counter < 110 -> 4
      msg_counter > 110 && msg_counter < 150 -> 5
      msg_counter > 150 && msg_counter < 190 -> 6
      msg_counter > 190 && msg_counter < 230 -> 7
      msg_counter > 230 && msg_counter < 270 -> 8
      msg_counter > 270 && msg_counter < 310 -> 9
      msg_counter > 310 && msg_counter < 350 -> 10
      msg_counter > 350 && msg_counter < 390 -> 11
      msg_counter > 390 && msg_counter < 430 -> 12
      msg_counter > 430 && msg_counter < 470 -> 13
      msg_counter > 470 && msg_counter < 510 -> 14
      msg_counter > 510 -> 20
      true -> 10
    end
  end


end
