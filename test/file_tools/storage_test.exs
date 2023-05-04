defmodule FileTools.StorageTest do
  use ExUnit.Case

  import FileTools.Storage

  @storage1 "test/fixtures/files1.csv"

  test "load_storage" do
    res = load_storage(@storage1)
    IO.inspect res
    assert map_size(res) == 7
    assert length(res["4d8f17301c2cd86271a57f4335e8644d"]) == 2
  end

  test "run" do
    res = load_storage("data/files.csv")
    IO.inspect map_size(res)
  end
end
