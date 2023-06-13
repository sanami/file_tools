defmodule FileTools.FileWorkerTest do
  use ExUnit.Case

  import FileTools.FileWorker

  @file1 "test/fixtures/data1.txt"

  setup do
    :ok
  end

  test "file_time" do
    stat1 = File.stat!(@file1)
    IO.inspect stat1

    res = file_time(stat1.mtime)
    IO.inspect res
    assert %DateTime{} = res
  end
end
