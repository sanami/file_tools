defmodule FileTools.FileDispatcher do
  use GenServer
  require Logger

  @me __MODULE__
  # API
  def start_link(init_arg) do
    GenServer.start_link(@me, init_arg, name: @me)
  end

  def queue_file(file_path, file_stat) do
    GenServer.cast @me, {:process, file_path, file_stat}
  end

  def take_file do
    GenServer.call @me, :take_file, :infinity
  end

  def set_find_status(status) do
    GenServer.call @me, {:set_find_status, status}, :infinity
  end

  # Callbacks
  @impl true
  def init(init_arg) do
    Logger.info "FileDispatcher.init #{init_arg}"
    state = %{queue: [], find_status: :not_started, worker_count: 0, max_worker_count: :erlang.system_info(:logical_processors_available)}
    {:ok, state}
  end

  @impl true
  def handle_cast({:process, file_path, file_stat}, state) do
    new_state = Map.update state, :queue, [], fn queue ->
      [{file_path, file_stat} | queue]
    end
    # Logger.debug "FileDispatcher.handle_cast #{length(new_state[:queue])} #{file_path}"

    if state[:worker_count] < state[:max_worker_count] do
      FileTools.FileSupervisor.add_worker
      {:noreply, %{new_state | worker_count: state[:worker_count] + 1}}
    else
      {:noreply, new_state}
    end
  end

  @impl true
  def handle_call({:set_find_status, status}, _from, state) do
    Logger.debug "FileDispatcher.handle_call set_find_status #{status} #{length(state[:queue])}"

    {:reply,  :ok, %{state | find_status: status}}
  end

  @impl true
  def handle_call(:take_file, _from, state) do
    if length(state[:queue]) == 0 do
      if state[:find_status] == :completed do
        {:reply, :finish, %{state | worker_count: state[:worker_count] - 1}}
      else
        {:reply, :wait, state}
      end
    else
      {file, new_state} = Map.get_and_update state, :queue, fn queue ->
        [file | new_queue] = queue
        {file, new_queue}
      end
      {:reply, {:process_file, file}, new_state}
    end
  end
end
