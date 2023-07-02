defmodule FileTools.Application do
  use Application
  require Logger

  @impl true
  def start(type, args) do
    Logger.info "FileTools.Application.start #{type} #{args}"

    if Mix.env() == :test do
      {:ok, self()}
    else
      children = [
        {FileTools.Storage, "data/files.csv"},
        {FileTools.FileSupervisor, 1},
        {FileTools.FileDispatcher, %{}},
        {FileTools.FileFinder, "/media/veracrypt1/frost/downloads"}
      ]

      opts = [strategy: :rest_for_one, name: FileTools.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

  @impl true
  def stop(state) do
    Logger.info "FileTools.Application.stop #{state}"
    :ok
  end
end
