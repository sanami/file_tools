defmodule Storage.HashBasedTest do
  use ExUnit.Case

  alias Storage.HashBased, as: Storage

  @storage1 "test/fixtures/files1.csv"
  @md51 "4d8f17301c2cd86271a57f4335e8644d"
  @attr1 {"1.jpg", 1715762, ~U[2013-12-01 13:14:51Z]}

  test "load_storage" do
    res = Storage.load_storage(@storage1)
    IO.inspect res
    assert map_size(res[:md5]) == 7
    assert length(res[:md5][@md51]) == 3

    assert map_size(res[:attr]) == 8
    assert length(res[:attr][@attr1]) == 2

    assert res[:file] == @storage1
  end

  describe "save_storage" do
    @tag tmp_dir: true
    test "csv", context do
      data1 = Storage.load_storage(@storage1)
      IO.inspect data1

      result_file1 = Path.join(context[:tmp_dir], "storage1.csv")
      IO.inspect result_file1

      res = Storage.save_storage(data1[:md5], result_file1, :csv)
      IO.inspect res

      res = File.read!(result_file1)
      IO.puts res
      assert String.length(res) == 950
    end

    @tag tmp_dir: true
    test "md5", %{tmp_dir: tmp_dir} do
      data1 = Storage.load_storage(@storage1)
      result_file1 = Path.join(tmp_dir, "files.md5")
      IO.inspect result_file1

      res = Storage.save_storage(data1[:md5], result_file1, :md5)
      IO.inspect res

      res = File.read!(result_file1)
      IO.puts res
      assert String.length(res) == 511
    end
  end

  test "backup_storage" do
    res = Storage.backup_storage(@storage1, true)
    IO.inspect res
    assert String.starts_with?(res, "tmp/backup")
  end

  test "exists?" do
    data1 = Storage.load_storage(@storage1)

    assert Storage.exists?(data1, :md5, @md51) == true
    assert Storage.exists?(data1, :md5, "not_exist") == false
    assert Storage.exists?(data1, :attr, @attr1) == true
    assert Storage.exists?(data1, :attr, {}) == false
    assert Storage.exists?(data1, :attr, 1) == false
  end
end
