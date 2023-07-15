defmodule FileTools.Storage do
  use GenServer
  require Logger

  @me __MODULE__
  @storage_module Storage.HashBased

  def start_link(init_arg) do
    GenServer.start_link(@me, init_arg, name: @me)
  end

  def exists?(type, key) do
    GenServer.call(@me, {:exists?, type, key}, :infinity)
  end

  def add(row) do
    GenServer.cast(@me, {:add, row})
  end

  def save do
    GenServer.call(@me, :save, :infinity)
  end

  # Callbacks
  @impl true
  def init(storage_file) do
    Logger.info "Storage.init #{storage_file}"
    state = @storage_module.init(%{}, storage_file)
    {:ok, state}
  end

  @impl true
  def handle_call({:exists?, type, key}, _from, state) do
    res = @storage_module.exists?(state, type, key)
    {:reply, res, state}
  end

  @impl true
  def handle_call(:save, _from, state) do
    new_state = @storage_module.save(state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:add, row}, state) do
    new_state = @storage_module.add(state, row)
    {:noreply, new_state}
  end
end
