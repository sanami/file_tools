defmodule FileTools.FileSupervisor do
  use DynamicSupervisor
  require Logger

  @me __MODULE__

  def start_link(init_arg) do
    DynamicSupervisor.start_link(@me, init_arg, name: @me)
  end

  def add_worker do
    {:ok, _pid} = DynamicSupervisor.start_child(@me, FileTools.FileWorker)
  end

  # Callbacks
  @impl true
  def init(init_arg) do
    Logger.info "FileSupervisor.init #{init_arg}"
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
