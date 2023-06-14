defmodule FileTools.FileWorker do
  use GenServer, restart: :transient

  require Logger

  @me __MODULE__
  @file_buffer_size 1048576

  def start_link(init_arg) do
    GenServer.start_link(@me, init_arg)
  end

  def process_file(file_path, file_stat) do
    name = Path.basename(file_path)
    size = file_stat.size
    mtime = file_time(file_stat.mtime)

    unless FileTools.Storage.exists?(:attr, {name, size, mtime}) do
      Logger.info "FileWorker.process_file #{file_path}"

      data = %{
        archive_path: "",
        crc32: "",
        fs_path: file_path,
        md5: file_hash(file_path, :md5),
        mtime: mtime,
        size: size
      }

      FileTools.Storage.add(data)
    end
  end

  def file_time(time) do
    {{y, m, d}, {hh, mm, ss}} = time
    DateTime.new!(Date.new!(y, m, d), Time.new!(hh, mm, ss))
  end

  def file_hash(file_path, algo \\ :md5, file_buffer_size \\ @file_buffer_size) do
    File.stream!(file_path, [], file_buffer_size)
    |> Enum.reduce(
      :crypto.hash_init(algo),
      fn (block, hash) ->
        :crypto.hash_update(hash, block)
      end)
    |> :crypto.hash_final
    |> Base.encode16
    |> String.downcase
  end

  # Callbacks
  @impl true
  def init(init_arg) do
    Logger.info "FileWorker.init #{init_arg}"
    Process.send_after(self(), :request_file, 0)
    state = %{}

    {:ok, state}
  end

  @impl true
  def handle_info(:request_file, state) do
    case FileTools.FileDispatcher.take_file do
      {:process_file, {file_path, file_stat}} ->
        process_file(file_path, file_stat)
        Process.send_after(self(), :request_file, 0)
        {:noreply, state}

      :finish ->
        Logger.debug "complete"
        {:stop, :normal, state}

      _ ->
        Logger.debug "wait"
        Process.send_after(self(), :request_file, 1000) # wait
        {:noreply, state}
    end
 end
end
