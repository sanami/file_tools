defmodule Mix.Tasks.Scan do
  use Mix.Task

  @shortdoc "Auto run scan"
  def run(_args) do
    Mix.Task.run("run", ["--no-halt", "--", "scan"])
  end
end
