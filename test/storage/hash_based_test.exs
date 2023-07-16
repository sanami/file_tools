defmodule Storage.HashBasedTest do
  use ExUnit.Case

  alias Storage.HashBased, as: Storage

  @storage1 "test/fixtures/files1.csv"
  @md51 "4d8f17301c2cd86271a57f4335e8644d"
  @attr1 {"1.jpg", 1715762, ~U[2013-12-01 13:14:51Z]}

  test "load_storage" do
    {md5, attr} = Storage.load_storage(@storage1)
    IO.inspect md5
    assert map_size(md5) == 7
    assert length(md5[@md51]) == 3

    IO.inspect attr
    assert map_size(attr) == 8
    assert length(attr[@attr1]) == 2
  end

  describe "save_storage" do
    @tag tmp_dir: true
    test "csv", context do
      state1 = Storage.load(%{}, @storage1)
      result_file1 = Path.join(context[:tmp_dir], "storage1.csv")
      IO.inspect result_file1

      res = Storage.save_storage(state1, result_file1, :csv)
      IO.inspect res

      res = File.read!(result_file1)
      IO.puts res
      assert String.length(res) == 950
    end

    @tag tmp_dir: true
    test "md5", %{tmp_dir: tmp_dir} do
      state1 = Storage.load(%{}, @storage1)
      result_file1 = Path.join(tmp_dir, "files.md5")
      IO.inspect result_file1

      res = Storage.save_storage(state1, result_file1, :md5)
      IO.inspect res

      res = File.read!(result_file1)
      IO.puts res
      assert String.length(res) == 511
    end
  end

  test "exists?" do
    state1 = Storage.load(%{}, @storage1)

    assert Storage.exists?(state1, :md5, @md51) == true
    assert Storage.exists?(state1, :md5, "not_exist") == false
    assert Storage.exists?(state1, :attr, @attr1) == true
    assert Storage.exists?(state1, :attr, {}) == false
    assert Storage.exists?(state1, :attr, 1) == false
  end
end
