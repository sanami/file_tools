defmodule FileToolsTest do
  use ExUnit.Case
  doctest FileTools

  test "hello" do
    assert FileTools.hello() == :world
  end
end
