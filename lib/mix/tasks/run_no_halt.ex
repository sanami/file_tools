defmodule Mix.Tasks.RunNoHalt do
  use Mix.Task

  @shortdoc "Runs the application without halting"
  def run(args) do
    Mix.shell.info("Running application without halting")
    Mix.Task.run("run", [ "--no-halt" | args ])
  end
end
