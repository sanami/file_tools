defmodule FileTools.StorageTest do
  use ExUnit.Case

  alias FileTools.Storage

  @storage1 "test/fixtures/files1.csv"
  @md51 "4d8f17301c2cd86271a57f4335e8644d"
  @attr1 {"1.jpg", 1715762, ~U[2013-12-01 13:14:51Z]}

  setup do
    start_supervised({FileTools.Storage, @storage1})
    :ok
  end

  test "exists?" do
    assert Storage.exists?(:md5, @md51) == true
    assert Storage.exists?(:md5, "not_exist") == false
    assert Storage.exists?(:attr, @attr1) == true
    assert Storage.exists?(:attr, {}) == false
  end

  test "add" do
    assert Storage.exists?(:md5, "md5") == false

    row = %{
      archive_path: "",
      crc32: "",
      fs_path: "/file1",
      md5: "md5",
      mtime: elem(@attr1, 2),
      size: 1
    }
    IO.inspect row

    Storage.add(row)
    assert Storage.exists?(:md5, "md5")
  end
end
