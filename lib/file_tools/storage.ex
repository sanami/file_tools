defmodule FileTools.Storage do
  use Agent

  @me __MODULE__

  def start_link(storage_name) do
    storage = load_storage(storage_name)
    Agent.start_link(fn -> storage end, name: @me)
  end

  def load_storage(storage_name) do
    storage_name
    |> File.stream!
    |> CSV.decode!(headers: true)
    |> Enum.reduce(%{}, fn row, acc ->
      Map.update acc, row["md5"], [row], fn existing_value -> [row | existing_value] end
    end)
  end
end

