defmodule FileToolsTest do
  use ExUnit.Case

  test "auto_scan" do
    assert FileTools.auto_scan? == false
  end
end
