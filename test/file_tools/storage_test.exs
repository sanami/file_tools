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

  @tag tmp_dir: true
  test "save_storage", context do
    data1 = load_storage(@storage1)
    IO.inspect data1

    result_file1 = Path.join(context[:tmp_dir], "storage1.csv")
    IO.inspect result_file1

    res = save_storage(data1, result_file1)
    IO.inspect res

    res = File.read!(result_file1)
    IO.puts res
    assert File.stat!(@storage1).size == File.stat!(result_file1).size
  end
end
