defmodule Router do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{} , [])
  end

  @impl true
  def init(_init_arg) do
    list_pid = []
    list_msg = []
    counter = 0
    state = %{:list_msg => list_msg, :list_pid => list_pid, :counter => counter}
    {:ok, state}
  end

  @impl true
  def handle_cast({:fetch_data, msg, flow_pid}, state) do
    list_msg = state[:list_msg]
    list_pid = state[:list_pid]
    counter = state[:counter]
    list_msg = list_msg ++ [msg]

    workers_nr = GenServer.call(flow_pid, :workers_nr)

    list_pid = if workers_nr < DynSupervisor.count_children()[:workers] do
      rm_slave(list_pid)
    else
      list_pid
    end

    {list_pid, list_msg} = if workers_nr > DynSupervisor.count_children()[:workers] do
      add_slave(list_msg, list_pid)
    else
      {list_pid, list_msg}
    end

    {list_pid, list_msg, counter} = reutilise_slave(list_pid, list_msg, counter)
    state = %{:list_msg => list_msg, :list_pid => list_pid, :counter => counter}
    {:noreply, state}
  end

  #Private
  defp add_slave(list_msg, list_pid) do
    #generate a random name
    name = generate_name()
    msg = List.last(list_msg)

    {state, pid} = DynSupervisor.add_slave(name, msg)
    list_pid_new = [pid | list_pid]
    list_msg = List.delete_at(list_msg, -1)
    if state == :error do
      {list_pid, list_msg}
    else
      {list_pid_new, list_msg}
    end
  end

  defp rm_slave(list_pid) do
    pid = List.last(list_pid)
    DynSupervisor.rm_slave(pid)
    List.delete_at(list_pid, -1)
  end

  defp reutilise_slave(list_pid, list_msg, counter) do
    list_pid_size = Enum.count(list_pid)

    counter = if counter > list_pid_size do
      0
    else
      counter
    end

    pid = Enum.at(list_pid, counter)
    msg = List.last(list_msg)
    list_msg = List.delete_at(list_msg, -1)
    GenServer.cast(pid, {:rtl, msg})

    counter = counter + 1
    {list_pid, list_msg, counter}
  end

  defp generate_name do
    ?a..?z|> Enum.take_random(6)|> List.to_string()
  end

end
