defmodule Storage.EtsBasedTest do
  use ExUnit.Case

  alias Storage.EtsBased, as: Storage

  @storage1 "test/fixtures/files1.csv"
  @md51 "4d8f17301c2cd86271a57f4335e8644d"
  @attr1 {"1.jpg", 1715762, ~U[2013-12-01 13:14:51Z]}

  setup do
    Storage.init(%{})
    :ok
  end

  test "load" do
    res = Storage.load(%{}, @storage1)
    IO.inspect res
    assert res[:file] == @storage1

    data1 = Storage.get_data(:md5, @md51)
    IO.inspect data1
    assert length(data1) == 3

    data2 = Storage.get_data(:attr, @attr1)
    IO.inspect data2
    assert length(data2) == 2

    # IO.inspect :ets.lookup(:md5_storage, "4d8f17301c2cd86271a57f4335e8644d")
  end

  describe "save_storage" do
    @tag tmp_dir: true
    test "csv", context do
      state1 = Storage.load(%{}, @storage1)
      result_file1 = Path.join(context[:tmp_dir], "storage1.csv")
      IO.inspect result_file1

      res = Storage.save_storage(state1, result_file1, :csv)
      assert res == :ok

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
      assert res == :ok

      res = File.read!(result_file1)
      IO.puts res
      assert String.length(res) > 500
    end
  end

  test "exists?" do
    state1 = %{}
    Storage.load(state1, @storage1)

    assert Storage.exists?(state1, :md5, @md51) == true
    assert Storage.exists?(state1, :md5, "not_exist") == false
    assert Storage.exists?(state1, :attr, @attr1) == true
    assert Storage.exists?(state1, :attr, {}) == false
    assert Storage.exists?(state1, :attr, 1) == false
  end
end
