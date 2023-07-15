defmodule FileTools.Storage do
  use GenServer
  require Logger

  @me __MODULE__
  @headers ~w(md5 fs_path size mtime crc32 archive_path)a

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
    state = load_storage(storage_file)

    {:ok, state}
  end

  @impl true
  def handle_call({:exists?, type, key}, _from, state) do
    res = Map.has_key?(state[type], key)
    {:reply, res, state}
  end

  @impl true
  def handle_call(:save, _from, state) do
    new_state = if state[:is_changed] do
      csv_file = state[:file]
      backup_storage(csv_file)

      Logger.info "Storage.save CSV #{csv_file}"
      save_storage(state[:md5], csv_file, :csv)

      md5_file = if String.ends_with?(csv_file, ".csv") do
        String.replace(csv_file, ~r/.csv\z/, ".md5", global: false)
      else
        csv_file <> ".md5"
      end

      Logger.info "Storage.save MD5 #{md5_file}"
      save_storage(state[:md5], md5_file, :md5)

      %{state | is_changed: false}
    else
      Logger.info "Storage.save NOT CHANGED"
      state
    end

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:add, row}, state) do
    md5_storage = add_md5_data(state[:md5], row)
    attr_storage = add_attr_data(state[:attr], row)
    new_state = %{state | md5: md5_storage, attr: attr_storage, is_changed: true}

    {:noreply, new_state}
  end

  # Internal
  def add_md5_data(md5_storage, row) do
    Map.update(md5_storage, row[:md5], [row], fn existing_rows ->
      [row | existing_rows]
    end)
  end

  def add_attr_data(attr_storage, row) do
    key = {Path.basename(row[:fs_path]), row[:size], row[:mtime]}

    Map.update(attr_storage, key, [row], fn existing_rows ->
      [row | existing_rows]
    end)
  end

  def load_storage(storage_file) do
    md5_storage = storage_file
    |> File.stream!
    |> CSV.decode!(headers: @headers)
    |> Stream.drop(1) # header row
    |> Stream.map(fn row ->
        {:ok, mtime, _} = DateTime.from_iso8601(row[:mtime])
        size = String.to_integer(row[:size])
        %{row | mtime: mtime, size: size}
      end)
    |> Enum.reduce(%{}, fn row, acc ->
      add_md5_data(acc, row)
    end)

    attr_storage = Enum.reduce(md5_storage, %{}, fn {_md5, rows}, acc ->
      Enum.reduce(rows, acc, fn row, acc ->
        add_attr_data(acc, row)
      end)
    end)

    Logger.info "Storage size: #{map_size(md5_storage)}"
    %{md5: md5_storage, attr: attr_storage, file: storage_file, is_changed: false}
  end

  def save_storage(storage, storage_file, :csv) do
    stream = Stream.transform storage, nil, fn {_md5, dup_entries}, acc ->
      # dup_entries = Enum.map dup_entries, fn row -> Map.values(row) end
      {dup_entries, acc}
    end

    File.open!(storage_file, [:write, :utf8], fn file ->
      stream
      |> CSV.encode(delimiter: "\n", headers: @headers)
      |> Enum.each(&IO.write(file, &1))
    end)
  end

  def save_storage(storage, storage_file, :md5) do
    File.open! storage_file, [:write, :utf8], fn file ->
      Enum.each storage, fn {_md5, dup_entries} ->
        row = hd(dup_entries)
        IO.write(file, [row[:md5], " ", "*", row[:fs_path], "\n"])
      end
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
