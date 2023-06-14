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

  describe "file_hash" do
    test "md5" do
      res = file_hash(@file1, :md5, 1)
      IO.inspect res
      assert res == "a2ef74a76b2bfcfe14817a27c511759c"
    end

    test "sha256" do
      res = file_hash(@file1, :sha256, 1)
      IO.inspect res
      assert res == "55ca99ac594667d0ed8bce3f924020bc15840c8d29f316485d428354d8740606"
    end
  end
end
