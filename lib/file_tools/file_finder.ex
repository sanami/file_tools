defmodule FileTools.FileFinder do
  use GenServer
  require Logger

  @me __MODULE__
  @min_size 1000_000

  def start_link(init_arg) do
    GenServer.start_link(@me, init_arg, name: @me)
  end

  def done do
    GenServer.cast(@me, :done)
  end

  # Callbacks
  @impl true
  def init(folder) do
    Logger.info "FileFinder.init #{folder}"
    state = %{folder: folder}
    Process.send_after(self(), :run, 0)

    {:ok, state}
  end

  @impl true
  def handle_info(:run, state) do
    run(state[:folder])
    {:noreply, state}
  end

  @impl true
  def handle_cast(:done, state) do
    FileTools.Storage.save()

    unless IEx.started?(), do: System.stop(0) # exit app

    {:noreply, state}
  end

  def list_folder(folder) do
    Logger.debug "FileFinder.list_folder #{folder}"

    File.ls!(folder)
    |> Enum.reduce([], fn entry, child_tasks ->
        entry = Path.join(folder, entry)
        case File.lstat(entry) do
          {:ok, stat} ->
            case stat.type do
              :directory ->
                task = Task.async(FileTools.FileFinder, :list_folder, [entry])
                [task|child_tasks]
              :regular ->
                if stat.size >= @min_size, do: FileTools.FileDispatcher.queue_file(entry, stat)
                child_tasks
              _ ->
                child_tasks
            end
          {:error, reason} ->
            Logger.error reason
            child_tasks
        end
      end)
    |> Task.await_many(:infinity)

    Logger.debug "FileFinder.list_folder done #{folder}"
    :ok
  end

  def run(start_folder) do
    Logger.info "FileFinder.run #{start_folder}"
    FileTools.FileDispatcher.set_find_status(:started)
    list_folder(start_folder)
    FileTools.FileDispatcher.set_find_status(:completed)
  end
end
