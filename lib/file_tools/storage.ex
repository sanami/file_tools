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
    state = %{}
    |> @storage_module.init
    |> @storage_module.load(storage_file)

    {:ok, state}
  end

  @impl true
  def handle_call({:exists?, type, key}, _from, state) do
    res = @storage_module.exists?(state, type, key)
    {:reply, res, state}
  end

  @impl true
  def handle_call(:save, _from, state) do
    new_state = save(state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:add, row}, state) do
    new_state = @storage_module.add(state, row)
    {:noreply, new_state}
  end

  # Internal
  def save(state) do
    if state[:is_changed] do
      csv_file = state[:file]
      backup_storage(csv_file)

      Logger.info "Storage.save CSV #{csv_file}"
      @storage_module.save_storage(state, csv_file, :csv)

      md5_file = if String.ends_with?(csv_file, ".csv") do
        String.replace(csv_file, ~r/.csv\z/, ".md5", global: false)
      else
        csv_file <> ".md5"
      end

      Logger.info "Storage.save MD5 #{md5_file}"
      @storage_module.save_storage(state, md5_file, :md5)

      %{state | is_changed: false}
    else
      Logger.info "Storage.save NOT CHANGED"
      state
    end
  end

  def backup_storage(storage_file, pretend \\ false) do
    backup_folder = "tmp/backup"
    File.mkdir_p(backup_folder)

    with {:ok, stat} <- File.stat(storage_file) do
      mtime = stat.mtime |> FileTools.FileWorker.file_time |> DateTime.to_unix
      backup_file = Path.join(backup_folder, "#{Path.basename(storage_file)}.#{mtime}")

      Logger.info "Storage.backup_storage #{backup_file}"
      unless pretend, do: File.rename(storage_file, backup_file)

      backup_file
    end
  end
end
