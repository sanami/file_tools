defmodule FileTools.Storage do
  use Agent
  require Logger

  @me __MODULE__
  @headers ~w(md5 fs_path size mtime crc32 archive_path)a

  def start_link(storage_name) do
    storage = load_storage(storage_name)
    Agent.start_link(fn -> storage end, name: @me)
  end

  def load_storage(storage_name) do
    storage = storage_name
    |> File.stream!
    |> CSV.decode!(headers: @headers)
    |> Enum.reduce(%{}, fn row, acc ->
      Map.update(acc, row[:md5], [row], fn existing_rows ->
        [row | existing_rows]
      end)
    end)
    |> Map.delete("md5") # headers line

    Logger.info "Storage size: #{map_size(storage)}"
    storage
  end

  def save_storage(storage, storage_path) do
    stream = Stream.transform storage, nil, fn {_md5, dup_entries}, acc ->
      # dup_entries = Enum.map dup_entries, fn row -> Map.values(row) end
      {dup_entries, acc}
    end

    IO.inspect Enum.take(stream, 2)

    File.open!(storage_path, [:write, :utf8], fn file ->
      stream
      |> CSV.encode(delimiter: "\n", headers: @headers)
      |> Enum.each(&IO.write(file, &1))
    end)
  end
end
