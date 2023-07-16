defmodule Storage.HashBased do
  @behaviour Storage.Interface

  require Logger

  @headers ~w(md5 fs_path size mtime crc32 archive_path)a

  @impl true
  def init(state) do
    state
  end

  @impl true
  def exists?(state, type, key) do
    Map.has_key?(state[type], key)
  end

  @impl true
  def add(state, row) do
    md5_storage = add_md5_data(state[:md5], row)
    attr_storage = add_attr_data(state[:attr], row)
    %{state | md5: md5_storage, attr: attr_storage, is_changed: true}
  end

  @impl true
  def save(state) do
    if state[:is_changed] do
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
  end

  @impl true
  def load(_state, storage_file) do
    {md5_storage, attr_storage} = load_storage(storage_file)
    Logger.info "Storage size: #{map_size(md5_storage)}"

    %{md5: md5_storage, attr: attr_storage, file: storage_file, is_changed: false}
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
    storage_file
    |> File.stream!
    |> CSV.decode!(headers: @headers)
    |> Stream.drop(1) # header row
    |> Stream.map(fn row ->
        {:ok, mtime, _} = DateTime.from_iso8601(row[:mtime])
        size = String.to_integer(row[:size])
        %{row | mtime: mtime, size: size}
      end)
    |> Enum.reduce({%{}, %{}}, fn row, {md5_storage, attr_storage} ->
      {add_md5_data(md5_storage, row), add_attr_data(attr_storage, row)}
    end)
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
