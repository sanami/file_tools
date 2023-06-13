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
    md5_storage = storage_name
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
    %{md5: md5_storage, attr: attr_storage}
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
