defmodule FileTools.CsvChecker do
  require Logger

  def run(:freenet_hashes, storage_file, input_file) do
    storage = Storage.HashBased.load_storage(storage_file)

    input_file
    |> File.stream!
    |> CSV.decode!(headers: true)
    |> Stream.with_index
    |> Enum.reduce([], fn {row, i}, acc ->
      md5 = row["Hashes.MD5"]
      if storage[:md5][md5] do
        Logger.debug "#{i} exist #{row["key"]}"
        acc
      else
        Logger.debug "#{i} new #{row["key"]}"
        [row | acc]
      end
    end)
  end
end
