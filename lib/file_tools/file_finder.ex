defmodule FileTools.FileFinder do
  require Logger

  def list_folder(parent_pid, folder) do
    Logger.debug "FileFinder.list_folder #{folder}"
    unless parent_pid, do: FileTools.FileDispatcher.set_find_status(:started)

    File.ls!(folder)
    |> Enum.reduce([], fn entry, child_pids ->
        entry = Path.join(folder, entry)
        case File.stat(entry) do
          {:ok, stat} ->
            case stat.type do
              :directory ->
                pid = spawn_link(FileTools.FileFinder, :list_folder, [self(), entry])
                [pid|child_pids]
              :regular ->
                FileTools.FileDispatcher.queue_file(entry, stat)
                child_pids
              _ ->
                child_pids
            end
          {:error, reason} ->
            Logger.error reason
            child_pids
        end
      end)
    |> Enum.each(fn pid ->
      receive do
        ^pid ->
          Logger.debug "FileFinder.list_folder done #{inspect pid}"
          :ok
      end
    end)

    if parent_pid, do: send(parent_pid, self()), else: FileTools.FileDispatcher.set_find_status(:completed)
  end

  def run(start_folder) do
    list_folder(nil, start_folder)
  end
end
