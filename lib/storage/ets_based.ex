defmodule Storage.EtsBased do
  @behaviour Storage.Interface

  require Logger

  @headers ~w(md5 fs_path size mtime crc32 archive_path)a
  @storage %{md5: :md5_storage, attr: :attr_storage}

  @impl true
  def init(state) do
    :ets.new(@storage[:md5], [:bag, :named_table, :protected])
    :ets.new(@storage[:attr], [:bag, :named_table, :protected])
    state
  end

  @impl true
  def exists?(_state, type, key) do
    :ets.member @storage[type], key
  end

  @impl true
  def add(state, row) do
    add_data(row)
    %{state | is_changed: true}
  end

  @impl true
  def load(_state, storage_file) do
    storage_file
    |> File.stream!
    |> CSV.decode!(headers: @headers)
    |> Stream.drop(1) # header row
    |> Stream.map(fn row ->
        {:ok, mtime, _} = DateTime.from_iso8601(row[:mtime])
        size = String.to_integer(row[:size])
        %{row | mtime: mtime, size: size}
      end)
    |> Enum.each(fn row ->
      add_data(row)
    end)

    info = :ets.info(@storage[:md5])
    Logger.info "Storage size: #{info[:size]}"
    %{file: storage_file, is_changed: false}
  end

  @impl true
  def save_storage(_state, storage_file, :csv) do
    File.open!(storage_file, [:write, :utf8], fn file ->
      :ets.tab2list(@storage[:md5])
      |> Stream.map(fn {_key, entry} -> entry end)
      |> CSV.encode(delimiter: "\n", headers: @headers)
      |> Enum.each(&IO.write(file, &1))
    end)
  end

  @impl true
  def save_storage(_state, storage_file, :md5) do
    File.open! storage_file, [:write, :utf8], fn file ->
      :ets.tab2list(@storage[:md5])
      |> Stream.map(fn {_key, entry} -> entry end)
      |> Stream.uniq_by(fn entry -> entry[:md5] end)
      |> Enum.each(fn entry ->
        IO.write(file, [entry[:md5], " ", "*", entry[:fs_path], "\n"])
      end)
    end
  end

  # Internal
  def add_data(row) do
    :ets.insert @storage[:md5], {row[:md5], row}

    attr = {Path.basename(row[:fs_path]), row[:size], row[:mtime]}
    :ets.insert @storage[:attr], {attr, row}
  end

  def get_data(type, key) do
    :ets.lookup @storage[type], key
  end
end
