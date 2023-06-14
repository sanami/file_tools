defmodule FileTools.Storage do
  use Agent
  require Logger

  @me __MODULE__
  @headers ~w(md5 fs_path size mtime crc32 archive_path)a

  def start_link(storage_file) do
    storage = load_storage(storage_file)
    Agent.start_link(fn -> storage end, name: @me)
  end

  def exists?(type, key) do
    Agent.get(@me, &Map.has_key?(&1[type], key), :infinity)
  end

  def save do
    Agent.get @me, fn storage ->
      backup_storage(storage[:file])
      save_storage(storage[:md5], storage[:file])
    end
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
        Map.update(acc, row[:md5], [row], fn existing_rows ->
          [row | existing_rows]
        end)
      end)

    attr_storage = Enum.reduce(md5_storage, %{}, fn {_md5, rows}, acc ->
      Enum.reduce(rows, acc, fn row, acc ->
        key = {Path.basename(row[:fs_path]), row[:size], row[:mtime]}

        Map.update(acc, key, [row], fn existing_rows ->
          [row | existing_rows]
        end)
      end)
    end)

    Logger.info "Storage size: #{map_size(md5_storage)}"
    %{md5: md5_storage, attr: attr_storage, file: storage_file}
  end

  def save_storage(storage, storage_file) do
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

  def backup_storage(storage_file, pretend \\ false) do
    backup_folder = "tmp/backup"
    File.mkdir_p(backup_folder)

    with {:ok, stat} <- File.stat(storage_file) do
      mtime = stat.mtime |> FileTools.FileWorker.file_time |> DateTime.to_unix
      backup_file = Path.join(backup_folder, "#{Path.basename(storage_file)}.#{mtime}")

      Logger.info "backup_storage #{storage_file}"
      unless pretend, do: File.rename(storage_file, backup_file)

      backup_file
    end
  end
end
