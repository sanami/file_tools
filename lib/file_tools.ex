defmodule FileTools do
  def auto_scan? do
    # !IEx.started?
    "scan" in System.argv
  end
end
