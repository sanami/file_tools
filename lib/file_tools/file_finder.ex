defmodule FileTools.FileFinder do
  require Logger

  @min_size 1000_000

  def list_folder(folder) do
    Logger.debug "FileFinder.list_folder #{folder}"

    File.ls!(folder)
    |> Enum.reduce([], fn entry, child_tasks ->
        entry = Path.join(folder, entry)
        case File.stat(entry) do
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
    FileTools.FileDispatcher.set_find_status(:started)
    list_folder(start_folder)
    FileTools.FileDispatcher.set_find_status(:completed)
  end
end
