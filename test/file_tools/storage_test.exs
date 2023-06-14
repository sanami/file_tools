defmodule FileTools.StorageTest do
  use ExUnit.Case

  import FileTools.Storage

  @storage1 "test/fixtures/files1.csv"
  @md51 "4d8f17301c2cd86271a57f4335e8644d"
  @attr1 {"1.jpg", 1715762, ~U[2013-12-01 13:14:51Z]}

  test "load_storage" do
    res = load_storage(@storage1)
    IO.inspect res
    assert map_size(res[:md5]) == 7
    assert length(res[:md5][@md51]) == 3

    assert map_size(res[:attr]) == 8
    assert length(res[:attr][@attr1]) == 2

    assert res[:file] == @storage1
  end

  @tag tmp_dir: true
  test "save_storage", context do
    data1 = load_storage(@storage1)
    IO.inspect data1

    result_file1 = Path.join(context[:tmp_dir], "storage1.csv")
    IO.inspect result_file1

    res = save_storage(data1[:md5], result_file1)
    IO.inspect res

    res = File.read!(result_file1)
    IO.puts res
    assert String.length(res) == 950
  end

  test "exists?" do
    FileTools.Storage.start_link(@storage1)

    assert exists?(:md5, @md51) == true
    assert exists?(:md5, "not_exist") == false
    assert exists?(:attr, @attr1) == true
    assert exists?(:attr, {}) == false
  end

  test "backup_storage" do
    res = backup_storage(@storage1, true)
    IO.inspect res
    assert String.starts_with?(res, "tmp/backup")
  end
end
